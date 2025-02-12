'use strict';

/**
 * subscriptor service
 */

const { createCoreService } = require('@strapi/strapi').factories;

module.exports = createCoreService('api::subscriptor.subscriptor');
