# Example Bicep Repository

This is sample Bicep code that gets seeded into the repository created by this module. It is intended as a starting point that users can customize for their own infrastructure deployments.

## Resources Deployed

- **Virtual Network** (with a subnet)
- **Network Interface**
- **Virtual Machine** (Ubuntu Linux)

## Configuration

Environment-specific parameter values are provided via `.bicepparam` files in the `config/` directory (e.g. `dev.bicepparam`, `test.bicepparam`, `prod.bicepparam`).
