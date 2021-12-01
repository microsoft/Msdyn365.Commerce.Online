# Msdyn365 Commerce online

## License
License is listed in the [LICENSE](./LICENSE) file.

## Starter kit license
License for starter kit is listed in the [LICENSE](./module-library/LICENSE) file of starter pack.

## Prerequisites
1. Install [VS Code](https://code.visualstudio.com/)
1. Open command prompt in administrator mode
1. Install latest version of [NodeJS](https://nodejs.org/en/download/)
    * Verify version by running ```node -v``` in your command prompt
    * If you had a previous version of node installed, run ```npm upgrade -g``` to update all your global packages
1. Install [Yarn](https://yarnpkg.com/en/docs/install)
    * installation can be run from the website or with the command prompt npm package install as shown below
    ```
    c:\>npm install -g yarn
    ```

## Install Dependencies
1. From a command prompt, navigate to the root folder of your ECommerce SDK (c:\repos\myEcommerceSite in the example below)
1. Run the `yarn` command to grab all the latest dependency packages needed
    * This step can take several minutes to complete and should be done after any update to packages.json:
    ```
    c:\repos\MyEcommerceSite>yarn
    ```

## Running the app
1. Start the app
    * This step will take several seconds to complete.  When complete you will see an output indicating the server has started and the allocated port number (default 4000)
    ```
    c:\repos\MyEcommerceSite>yarn start
    ```
1. To test that the app is running successfully, launch the below pages in a browser:
    * http://localhost:4000/version
    * http://localhost:4000/?mock=default-page
1. To stop the app, in the command prompt hit Ctrl-c twice

## Modifiable code
Only the code under "src" folder is allowed to be completely customized and modified. Please use the following CLI commands to extend the starter kit modules or create new modules.

## Creating a new module
To add a new module called `campaignBanner`, run this command:
```
c:\repos\MyEcommerceSite>yarn msdyn365 add-module campaignBanner
```
This can take up to a minute or two to complete and will add a new module under `\src\modules\campaignBanner`.

## Previewing Modules
To view a specific module rendering locally in a browser, such as `campaignBanner`:
1. Start the app from a command prompt:
    ```
    c:\repos\MyEcommerceSite\yarn start
    ```
2. Launch the following pages in a browser.  Notice the module name in the query string parameter "type=MODULE_NAME":
    * http://localhost:4000/modules?type=campaignBanner
    * http://localhost:4000/modules?type=hero
    * http://localhost:4000/modules?type=banner

## Testing
Functional tests are built on [TestCafe NPM](https://www.npmjs.com/package/testcafe).
Functional test files should be added under `/test`. Run tests with this command:
```
yarn integration
```

## Online Documentaiton
Online documentation can be found [here](https://docs.microsoft.com/en-us/dynamics365/commerce/e-commerce-extensibility/overview)

## Third party Image and Video Usage restrictions

The software may include third party images and videos that are for personal use only and may not be copied except as provided by Microsoft within the demo websites.  You may install and use an unlimited number of copies of the demo websites., You may not publish, rent, lease, lend, or redistribute any images or videos without authorization from the rights holder, except and only to the extent that the applicable copyright law expressly permits doing so.
