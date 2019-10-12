resource "digitalocean_droplet" "test" {
  image = "docker-18-04"
  name = "test"
  region = "nyc3"
  size = "s-1vcpu-2gb"
  ssh_keys = [
    "${var.ssh_fingerprint}"
  ]

  connection {
      user = "root"
      type = "ssh"
      private_key = "${var.pvt_key}"
      host=self.ipv4_address
      timeout = "2m"
  }

  provisioner "remote-exec" {
    inline = [
      "apt-get install -y --fix-missing python-pip",
      "pip install docker-compose",
      "cd /usr/src",
      "git clone https://github.com/MIT-Tab/mit-tab.git",
      "cd mit-tab",
      "echo 'SENTRY_DSN=${var.sentry_dsn}' >> .env.secret",
      "echo 'TOURNAMENT_NAME=${self.name}' >> .env",
      "docker-compose up -d",
      "docker-compose run --rm web ./bin/setup password && docker-compose restart web && docker-compose restart nginx"
    ]
  }

  provisioner "remote-exec" {
    when = "destroy"
    inline = [
      "pip install s3cmd",
      "cd /usr/src/mit-tab",
      "docker-compose run --rm web python manage.py export_stats --root s3_backup",
      "mkdir -p s3_backup",
      "cp mittab/pairing_db.sqlite3 s3_backup/${self.name}-backup.db",
      "docker-compose run --rm web sqlite3 s3_backup/${self.name}.db 'delete from tab_scratch'",
      "s3cmd --host=nyc3.digitaloceanspaces.com --access_key=${var.do_access_key} --host-bucket=mittab-backups.nyc3.digitaloceanspaces.com --secret_key=${var.do_access_secret} --no-mime-magic put -r s3_backup/* s3://mittab-backups/${self.name}-$(date +%Y-%m-%s)/"
    ]
  }
}

resource "digitalocean_record" "test" {
  domain = "nu-tab.com"
  type = "A"
  name = "test"
  value = "${digitalocean_droplet.test.ipv4_address}"
}
