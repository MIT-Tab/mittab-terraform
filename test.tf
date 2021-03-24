resource "digitalocean_database_cluster" "tf_test_mysql" {
  name       = "tf-test-mysql"
  engine     = "mysql"
  version    = "8"
  size       = "db-s-1vcpu-1gb"
  region     = "nyc3"
  node_count = 1
}

resource "digitalocean_database_user" "tf_test_user" {
  cluster_id = digitalocean_database_cluster.postgres-example.id
  name       = "foobar"
}

resource "digitalocean_app" "tf_test_app" {
  spec {
    name = "mittab-tf-test"
    region="nyc3"

    database {
      name = "mysql"
      production = true
      engine = "MYSQL"
      db_name = "mittab_production"
      db_user = "mittab"
      cluster_name = "tf-test-mysql"
    }

    service {
      name = "web"
      environment_slug = "docker"
      instance_count = 1
      instance_size_slug = "professional-xs"
      http_port = 8000

      routes {
        path = "/"
      }

      git {
        repo_clone_url = "https://github.com/mit-tab/mit-tab.git"
        branch = "do-apps"
      }
    }

    static_site {
      name = "static"
      environment_slug = "docker"
      output_dir = "/var/www/tab/assets"
      routes {
        path = "/static"
      }
    }
  }
}


resource "digitalocean_record" "test" {
  domain = "nu-tab.com"
  type = "A"
  name = "test"
  value = "${digitalocean_droplet.test.ipv4_address}"
}
