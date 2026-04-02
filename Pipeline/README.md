# E-Commerce Extension — Azure DevOps Pipelines

This folder contains the Azure DevOps (ADO) pipeline definitions and supporting scripts to **build**, **pack**, and **upload** a Dynamics 365 Commerce e-commerce extension package to Dataverse.

## Prerequisites

| Requirement | Details |
|---|---|
| **Azure DevOps project** | An ADO project with access to create pipelines and variable groups. |
| **Azure AD App Registration** | An app registration with a client secret (or certificate). This is used for OAuth2 client-credentials authentication to Dataverse. |
| **Dataverse Application User** | The app registration must be added as an Application User in the target Dataverse environment with permissions to write to the `msprov_commerceextensionassets` table. |
| **Node.js 20.x** | The build pipeline uses Node.js 20.x (installed automatically by the pipeline). |

## Setup Instructions

### 1. Clone or fork this repository

Clone this repo into your own ADO project:

```
git clone <your-ado-repo-url>
```

### 2. Update `package.json`

Open `package.json` in the repo root and update these fields to match your project:

| Field | Example | Purpose |
|---|---|---|
| `name` | `Contoso.Commerce.Online` | Becomes the package name in Dataverse. |
| `version` | `1.0.0` | Package version stored in Dataverse. |

### 3. Create the Build Pipeline

1. In ADO, go to **Pipelines → New Pipeline**.
2. Select your repository and choose **Existing Azure Pipelines YAML file**.
3. Select the path: `Pipeline/YAML_Files/build-pipeline.yml`.
4. **Name the pipeline**: `Commerce-ECommerce-Extension-Build`.

> **Important:** The release pipeline references the build pipeline by name. If you choose a different name, update the `source` field in `release-pipeline.yml` to match.

#### What the build pipeline does

| Step | Description |
|---|---|
| Install Node.js 20.x | Sets up the Node runtime. |
| Install Yarn | Installs Yarn globally via npm. |
| `yarn install` | Installs all dependencies. |
| `yarn build` | Compiles the e-commerce application. |
| `yarn msdyn365 pack` | Packages the application into a `.zip` file. |
| Copy & Publish | Renames the zip with the build number and publishes it as a build artifact. |

### 4. Create the Variable Group

Go to **Pipelines → Library** and create a variable group named:

```
Commerce-ECommerce-Extension-Release-Variables
```

Add the following variables:

| Variable | Required | Description |
|---|---|---|
| `DataverseUrl` | Yes | Your Dataverse environment URL (e.g., `https://myorg.crm.dynamics.com/`). |
| `TenantId` | Yes | Azure AD tenant ID. |
| `ClientId` | Yes | Azure AD app registration client ID. |
| `ClientSecret` | Yes | App registration client secret. **Mark as secret** in the variable group. |
| `PackagePublisher` | Yes | Publisher name for the package in Dataverse (e.g., `Contoso`). |
| `PackageName` | No | Optional override for the package name. If empty, the name is read from `package.json` inside the zip. |

> If you rename the variable group, update the `group` field in `release-pipeline.yml` to match.

### 5. Create the Release Pipeline

1. In ADO, go to **Pipelines → New Pipeline**.
2. Select your repository and choose **Existing Azure Pipelines YAML file**.
3. Select the path: `Pipeline/YAML_Files/release-pipeline.yml`.
4. **Name the pipeline**: `Commerce-ECommerce-Extension-Release`.

#### What the release pipeline does

| Step | Description |
|---|---|
| Download artifact | Downloads the `.zip` produced by the build pipeline. |
| Upload to Dataverse | Extracts metadata (name, version, SDK version, SSK version) from the zip and creates a record in the `msprov_commerceextensionassets` table with asset type **E-Commerce (1)**. Then uploads the zip file in chunked mode. |

### 6. Run the Pipelines

1. **Run the build pipeline** first. It will produce a build artifact containing the packaged zip.
2. **Run the release pipeline**. It will download the artifact from the latest (or selected) build and upload it to Dataverse.

## How Package Metadata Is Resolved

The upload script (`UploadExtensionPackage.ps1`) resolves package metadata in this order:

| Field | Resolution Order |
|---|---|
| **Name** | `PackageName` variable (if set) → `package.json` `name` field → zip filename |
| **Version** | `package.json` `version` field → zip filename |
| **Publisher** | `PackagePublisher` variable (from variable group) |
| **SDK Version** | `version.json` `sdkVersion` field inside the zip |
| **SSK Version** | `version.json` `sskVersion` field inside the zip (stored in Additional Properties) |

## Customization

- **Change the package name**: Update `name` in `package.json`, or set the `PackageName` variable in the variable group to override it.
- **Change Node.js version**: Edit the `nodeVersion` variable in `build-pipeline.yml`.
- **Use certificate auth instead of secret**: Add a `CertificateThumbprint` variable to the variable group and update the release YAML to pass it instead of `ClientSecret`.
- **Auto-trigger release on build completion**: Change `trigger: none` to `trigger: true` under the `resources.pipelines` section in `release-pipeline.yml`.
- **Auto-trigger build on commit**: Change `trigger: none` to a branch filter (e.g., `trigger: [main]`) in `build-pipeline.yml`.
