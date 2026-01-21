# Usage

To actually use the data Corrosion gossips, your applications need:

API Access: Your services communicate with the local Corrosion agent via its HTTP API (for SQL queries) or the PostgreSQL wire protocol.

Subscriptions: If your app needs real-time updates (e.g., a proxy learning about a new service), it should use Corrosion's HTTP streaming subscriptions to receive push notifications when the 
local SQLite database changes.

Optional Templates: For legacy apps, you can use Rhai templates to automatically rewrite local configuration files whenever Corrosion state updates.

## Uncloud

In the Uncloud project (found in the [psviderski/uncloud](https://github.com/psviderski/uncloud) repository), Corrosion is used as the decentralized "source of truth" for the entire cluster's state. 

While Uncloud's primary daemon (uncloudd) is written in Go, it integrates Corrosion (written in Rust) to handle the complexities of distributed data consistency without a central control plane. 

### How Uncloud Uses Corrosion

Uncloud uses Corrosion to solve the problem of maintaining a synchronized view of the cluster across multiple machines: 

State Synchronization: When you deploy a container or add a machine, Uncloud writes that metadata to its local Corrosion instance. Corrosion then "gossips" this information to all other nodes in the cluster.

CRDT-Based SQLite: It leverages Corrosion's CRDT-based SQLite engine to ensure that even if multiple administrators make changes simultaneously, every machine eventually converges on the same configuration.

Decentralization: By using Corrosion, Uncloud avoids the need for a "leader" node or a quorum (like Raft in Kubernetes/Consul). If any machine stays online, the cluster state remains available.

Service Discovery: The built-in DNS and Caddy reverse proxy in Uncloud watch the local Corrosion database for changes. When a new service appears in the synchronized state, they automatically update routing rules. 

## Running it in Uncloud

When you use the Uncloud CLI (uc machine init), it automates the setup process by:
Installing Docker and the uncloudd (Go) binary.

Downloading and Installing the uncloud-corrosion binary to /usr/local/bin/.

Configuring Systemd: It sets up uncloud-corrosion.service to run as a background daemon on the host.

Networking: It configures a WireGuard mesh so that the Corrosion agents can safely gossip state over a private encrypted network