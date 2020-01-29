/**
 * Copyright (c) 2018 Microsoft Corporation
 * IHelloworld contentModule Interface Properties
 * THIS FILE IS AUTO-GENERATED - MANUAL MODIFICATIONS WILL BE LOST
 */

import * as Msdyn365 from '@msdyn365-commerce/core';

export interface IHelloworldConfig extends Msdyn365.IModuleConfig {
    title?: string;
}

export interface IHelloworldProps<T> extends Msdyn365.IModule<T> {
    config: IHelloworldConfig;
}
