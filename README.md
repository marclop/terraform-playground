# Terraform

This repo contains terraform command inside a docker container with Consul as a storage backend for Terraform.

## Requirements

* docker
* docker-compose

## Usage

### Terraform

#### Initialization


```
$ source terraform.bash
$ terraform_config
  Remote configuration updated
  Remote state configured and pulled.
```

### Vault

#### Initialization

Initialization using Consul as a storage backend and using the root key to create basic vault configs

```
$ vault init
  Key 1: c8b4a1ec3482c296e6604a4810157df395f9f3d654c54b03631c764c1428dab301
  Key 2: 2cd87bd50bf63621a357fba9b894506a4aa18ac8b036fa9ab0b6baa14a505d2a02
  Key 3: 6075c93f0ab4ba2ca6f9ca475b7190f85d8883227c9f2be075c6ac91e676d4e903
  Key 4: 0fb69fcbb952494250b2c5b50bdabfa7bcbe8923529413f8a02b3a1fb5fa53f504
  Key 5: 431b2d21b810c54f551cf45be83f7f35ab9780c99e3dc282655b2c2f19dcda3605
  Initial Root Token: bac0e5f0-69b4-3925-1156-64129cbbea74
  [..]
$ vault unseal c8b4a1ec3482c296e6604a4810157df395f9f3d654c54b03631c764c1428dab301
  Sealed: true
  Key Shares: 5
  Key Threshold: 3
  Unseal Progress: 1
$ vault unseal 2cd87bd50bf63621a357fba9b894506a4aa18ac8b036fa9ab0b6baa14a505d2a02
  Sealed: true
  Key Shares: 5
  Key Threshold: 3
  Unseal Progress: 2
$ vault unseal 6075c93f0ab4ba2ca6f9ca475b7190f85d8883227c9f2be075c6ac91e676d4e903
  Sealed: false
  Key Shares: 5
  Key Threshold: 3
  Unseal Progress: 0
$ vault auth bac0e5f0-69b4-3925-1156-64129cbbea74
  Successfully authenticated! The policies that are associated
  with this token are listed below:

  root
$ vault mount consul
  Successfully mounted 'consul' at 'consul'!
```

#### Policy creation

```
$ vault policy-write dev /vault/dev.hcl
  Policy 'dev' written.
$ vault policy-write dev-rw vault/dev-rw.hcl
  Policy 'dev-rw' written.
```

#### Token with policy attached

```
$ vault token-create -policy=dev
  cf3f90d0-6d32-2e8e-f8f7-790d8ba1c3dd
$ vault token-create -policy=dev-rw
  63ed72e0-4e32-7d3c-5153-79ddfbb1f1c6
```

#### Write/read generic secrets

```
$ vault write secret/dev/secret1 username=myuser password=mypassword lease=1h
  Success! Data written to: secret/dev/secret1
$ vault read -format=json secret/dev/secret1
{
	"lease_id": "secret/dev/secret1/688f2da0-ebc7-35a5-c925-3d273325887d",
	"lease_duration": 3600,
	"renewable": false,
	"data": {
    "lease": "1h",
		"password": "mypassword",
		"username": "myuser"
	}
}
```

### Consul

#### Register vault service with health check

```
$ register_service vault
  Status: 200
  {
    "ID": "vault",
    "Name": "vault",
    "Tags": [
      "vault",
    ],
    "Address": "172.17.0.18",
    "Port": 8200,
    "Check": {
      "Name": "Vault health check",
      "http": "http://172.17.0.18:8200/v1/sys/health",
      "Notes": "HTTP based health check",
      "Interval": "10s",
      "Timeout": "2s"
    }
  }
```

## Links

* [Consul UI](http://localhost:8500/ui)
* [Consul API](http://localhost:8500/v1)
* [Vault API](http://localhost:8200/v1)

## Cleanup

```
$ terraform_cleanup
Killing terraform_consulSlave_2...
Killing terraform_consulSlave_1...
Killing terraform_vault_1...
Killing terraform_consul_1...
Going to remove terraform_vault_1, terraform_consulSlave_2, terraform_consulSlave_1, terraform_consul_1
Removing terraform_consul_1...
Removing terraform_vault_1...
Removing terraform_consulSlave_2...
Removing terraform_consulSlave_1...
```
