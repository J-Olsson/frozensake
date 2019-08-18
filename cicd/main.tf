variable "region" {
  type    = string
  default = "northamerica-northeast1"
}

variable "zone" {
  type    = string
  default = "northamerica-northeast1a"
}

variable "service-key" {
  type    = string
  default = "./gcs-key.json"
}

variable "gitlab-db-user" {
  type    = string
  default = "gitlab"
}

provider "google" {
  credentials = "${file("${var.service-key}")}"
  project     = "${var.project}"
  region      = "${var.region}"
  zone        = "${var.zone}"
}

resource "random_password" "db-password" {
  length  = 16
  special = true
}

resource "gcp_storage_bucket" "${var.project}-uploads" {
  name      = "${var.project}-uploads"
  location  = "US"
  project   =  "${var.project}"
}
resource "gcp_storage_bucket" "${var.project}-artifacts" {
  name      = "${var.project}-artifacts"
  location  = "US"
  project   =  "${var.project}"
}
resource "gcp_storage_bucket" "${var.project}-lfs" {
  name      = "${var.project}-lfs"
  location  = "US"
  project   =  "${var.project}"
}
resource "gcp_storage_bucket" "${var.project}-packages" {
  name      = "${var.project}-packages"
  location  = "US"
  project   =  "${var.project}"
}
resource "gcp_storage_bucket" "${var.project}-registry" {
  name      = "${var.project}-registry"
  location  = "US"
  project   =  "${var.project}"
}

resource "google_compute_address" "gitlab-ip" {
  name = "gitlab-ip"

  labels = [
    cost_center = "CICD"
    purpose     = "CICD"
  ]
}

resource "google_compute_network" "gitlab-network" {
  name = "gitlab-network"
}

resource "google_compute_subnetwork" "gitlab-sql-db-net" {
  name = "gitlab-db-subnet"
  ip_cidr_range = "10.120.120.0/24"
  network = "${google_compute_network.gitlab-network.self_link}"
}

/*resource "google_compute_network_peering" "sql-to-gitlab" {

}*/

/*resource "google_compute_subnetwork" "gitlab-subnetwork" {

}*/

resource "google_sql_database_instance" "gitlab-master" {
  name             = "gitlab-master-instance"
  database_version = "POSTGRES_9_6"
  region           = "${var.region}"
  project          = "${var.project}"

  settings {
    tier = "db-f1-micro"
  }

  user_labels = [
    cost_center = "CICD"
    purpose     = "CICD"
  ]
}

resource "google_sql_database" "gitlab-postgres" {
  name     = "gitlab-db"
  instance = "${google_sql_database_instance.gitlab-master.name}"
}

resource "google_redis_instance" "gitlab-redis" {
  name           = "gitlab-redis"
  display_name   = "gitlab-redis"
  tier           = "BASIC"
  memory_size_gb = 2

  location_id        = "${var.zone}"
  authorized_network = "${google_compute_network.gitlab-network.self_link}"

  labels = [
    cost_center = "CICD"
    purpose     = "CICD"
  ]

  #redis_version not included, thus using latest supported
}

resource "google_container_cluster" "gitlab-cluster" {
  name         = "gitlab-kubernetes-cluster"
  location     = "${var.zone}"
  machine_type = "n1-standard-4"

  ip_allocation_policy = [
    use_ip_aliases = true
  ]
}

data "local_file" "pd-ssd-storage.yaml" {
  filename = "./pd-ssd-storage.yaml"
}

#resource kubectl_secret_1

data "local_file" "rails.yaml" {
  filename = "./rails.yaml"
}

#resource kubectl_secret_2

#ansible?