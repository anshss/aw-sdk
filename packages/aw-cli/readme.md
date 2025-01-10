# Agent Wallet CLI

The Agent Wallet CLI is a command-line interface (CLI) application designed to demonstrate the capabilities of agent wallets. It allows users to manage policies, delegate permissions, and execute tools within defined constraints. This tool is particularly useful for developers and administrators working with decentralized systems and Lit Protocol.

---

## Table of Contents

1. [Features](#features)
2. [Prerequisites](#prerequisites)
3. [Installation](#installation)
4. [Configuration](#configuration)
5. [Usage](#usage)
   - [Starting the CLI](#starting-the-cli)
   - [Selecting a Lit Network](#selecting-a-lit-network)
   - [Selecting Your Role](#selecting-your-role)
   - [Admin Actions](#admin-actions)
   - [Delegatee Actions](#delegatee-actions)
6. [Getting Test Tokens](#getting-test-tokens)
7. [Contributing](#contributing)
8. [License](#license)

---

## Features

- **Admin Role**: Set policies and manage delegatees.
- **Delegatee Role**: Execute tools within policy constraints.
- **Lit Action Tools**: Deploy tools to IPFS for decentralized execution.
- **Policy Management**: Define and enforce tool usage policies for delegatees.

---

## Prerequisites

Before you begin, ensure you have the following installed:

- [Node.js](https://nodejs.org/) (v16 or higher)
- [pnpm](https://pnpm.io/) (Package manager)
- A wallet (e.g., MetaMask) with a private key for authentication
- A [Pinata](https://www.pinata.cloud/) API key for IPFS interactions

---

## Installation

```bash
# Clone the repository
git clone https://github.com/your-username/agent-wallet-cli.git
cd agent-wallet-cli

# Install dependencies
pnpm install

# Build the project
pnpm build

Configuration
bash
Copy
```

# Rename the .env.example file to .env
mv .env.example .env

Open the .env file and add your Pinata API key:
plaintext
Copy

PINATA_API_KEY=your-pinata-api-key

Usage
Starting the CLI
bash
Copy

pnpm start:cli

The CLI will deploy Lit Action tools to IPFS and display a wall of text confirming the deployment.
Selecting a Lit Network

You will be prompted to select a Lit network:
plaintext
Copy

? Select a Lit network: › - Use arrow-keys. Return to submit.
❯   Datil Dev - Development network
    Datil Test
    Datil

    Datil Dev: For development purposes.

    Datil Test: For testing environments.

    Datil: For production use.

If you're just getting started, choose Datil. You can obtain test tokens (tstLit) from the Chronicle Yellowstone Faucet.
Selecting Your Role

Next, select your role:
plaintext
Copy

? Select your role: › - Use arrow-keys. Return to submit.
❯   Admin - Can set policies and manage delegatees
    Delegatee - Can execute tools within policy constraints

    Admin: For managing policies and delegatees.

    Delegatee: For executing tools within the constraints set by the admin.

Admin Actions

If you choose the Admin role:

    Enter your private key when prompted. This key remains local and is not shared.

    Use the following actions:

        Add Delegatee: Add a wallet address as a delegatee.

        Permit Tool: Allow a tool to be used by delegatees.

        Set Tool Policy: Define usage policies for delegatees.

Delegatee Actions

If you choose the Delegatee role:

    Restart the CLI by pressing ^C and running pnpm start:cli again.

    Select Delegatee as your role.

    Execute tools within the constraints set by the admin.
