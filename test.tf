resource "digitalocean_database_cluster" "tf_test_mysql" {
  name       = "tf-test-mysql"
  engine     = "mysql"
  version    = "8"
  size       = "db-s-1vcpu-1gb"
  region     = "nyc3"
  node_count = 1
}

resource "digitalocean_database_user" "tf_test_user" {
  cluster_id = digitalocean_database_cluster.tf_test_mysql.id
  name       = "mittab"
  mysql_auth_plugin = "mysql_native_password"
}

resource "digitalocean_database_db" "tf_test_db" {
  cluster_id = digitalocean_database_cluster.tf_test_mysql.id
  name       = "mittab_production"
}

resource "digitalocean_app" "tf_test_app" {
  spec {
    name   = "mittab-tf-test"
    region = "nyc3"

    env {
      key   = "TAB_PASSWORD"
      value = "password"
    }

    env {
      key = "MYSQL_DATABASE"
      value = "$${mysql.DATABASE}"
    }

    env {
      key = "MYSQL_PASSWORD"
      value = "$${mysql.PASSWORD}"
    }

    env {
      key = "MYSQL_USER"
      value = "$${mysql.USERNAME}"
    }

    env {
      key = "MYSQL_HOST"
      value = "$${mysql.HOSTNAME}"
    }

    env {
      key = "MYSQL_PORT"
      value = "$${mysql.PORT}"
    }

    database {
      name = "mysql"
      production = true
      engine = "MYSQL"
      db_name = digitalocean_database_db.tf_test_db.name
      db_user = digitalocean_database_user.tf_test_user.name
      cluster_name = digitalocean_database_cluster.tf_test_mysql.name
    }

    service {
      name = "web"
      instance_count = 1
      instance_size_slug = "professional-xs"
      http_port = 8000
      dockerfile_path = "Dockerfile"

      routes {
        path = "/"
      }

      github {
        repo = "MIT-Tab/mit-tab"
        branch = "do-apps"
        deploy_on_push = false
      }
    }

    static_site {
      name = "static"
      output_dir = "/var/www/tab/assets"
      dockerfile_path = "Dockerfile"
      routes {
        path = "/static"
      }

      github {
        repo = "MIT-Tab/mit-tab"
        branch = "do-apps"
        deploy_on_push = false
      }
    }
  }
}
