/*---------------------------------------------------------------------------------------------
 *  Copyright (c) Microsoft Corporation. All rights reserved.
 *  Licensed under the MIT License. See License.txt in the project root for license information.
 *--------------------------------------------------------------------------------------------*/

export interface IHelloworldData {
    /**
     * Use this file to hook up your data actions
     *
     * @dataAction ../actions/--ACTION-NAME-HERE--
     * @runAt server
     */
    actionResponse: {text: string};
}