import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:sqfentity/sqfentity.dart';
import 'package:sqfentity_gen/sqfentity_gen.dart';

part 'model.g.dart';

const Products = SqfEntityTable(
    tableName: 'product',
    primaryKeyName: 'id',
    primaryKeyType: PrimaryKeyType.integer_auto_incremental,
    useSoftDeleting: true,
    modelName: null,
    fields: [
      SqfEntityField('unique_id', DbType.integer, sequencedBy: productIdentity, isUnique: true, isIndex: true),
      SqfEntityField('ref_id', DbType.integer, isUnique: true, isIndex: true),
      SqfEntityField('business_id', DbType.integer),
      SqfEntityField('name', DbType.text),
      SqfEntityField('product_type', DbType.text),
      SqfEntityField('sku', DbType.text),
      SqfEntityField('price', DbType.real, defaultValue: 0.0),
      SqfEntityField('stock', DbType.real, defaultValue: 0.0),
      SqfEntityField('unit_name', DbType.text),
      SqfEntityField('alert', DbType.real, defaultValue: 0.0),
      SqfEntityField('expiry_period', DbType.text),
      SqfEntityField('expiry_period_type', DbType.text),
      SqfEntityField('weight', DbType.text),
      SqfEntityField('img', DbType.text),
      SqfEntityField('description', DbType.text),
      SqfEntityField('manufacturer', DbType.text),
      SqfEntityField('custom_field1', DbType.text),
      SqfEntityField('custom_field2', DbType.text),
      SqfEntityField('custom_field3', DbType.text),
      SqfEntityField('custom_field4', DbType.text),
      SqfEntityField('dateAdded', DbType.datetimeUtc),
      SqfEntityField('dateUpdated', DbType.datetimeUtc),
      SqfEntityField('dateSynced', DbType.datetimeUtc),
      SqfEntityField('isSynced', DbType.bool, defaultValue: false),
      SqfEntityField('isActive', DbType.bool, defaultValue: true),
      SqfEntityField('isCloudActive', DbType.bool, defaultValue: true),
    ]
);

const Variations = SqfEntityTable(
    tableName: 'variation',
    primaryKeyName: 'id',
    primaryKeyType: PrimaryKeyType.integer_auto_incremental,
    useSoftDeleting: true,
    modelName: null,
    fields: [
      SqfEntityField('ref_id', DbType.integer, isUnique: true, isIndex: true),
      SqfEntityField('variation_id', DbType.integer),
      SqfEntityField('name', DbType.text),
      SqfEntityField('sub_sku', DbType.text),
      SqfEntityField('price', DbType.real, defaultValue: 0.0),
      SqfEntityField('stock', DbType.real, defaultValue: 0.0),
      SqfEntityField('unit_name', DbType.text),
      SqfEntityField('alert', DbType.real, defaultValue: 0.0),
      SqfEntityField('expiry_period', DbType.text),
      SqfEntityField('expiry_period_type', DbType.text),
      SqfEntityField('weight', DbType.text),
      SqfEntityField('img', DbType.text),
      SqfEntityField('description', DbType.text),
      SqfEntityField('dateAdded', DbType.datetimeUtc),
      SqfEntityField('dateUpdated', DbType.datetimeUtc),
      SqfEntityField('dateSynced', DbType.datetimeUtc),
      SqfEntityField('isSynced', DbType.bool, defaultValue: false),
      SqfEntityField('isActive', DbType.bool, defaultValue: true),
      SqfEntityField('isCloudActive', DbType.bool, defaultValue: true),
      SqfEntityFieldRelationship(
          parentTable: Products,
          deleteRule: DeleteRule.CASCADE,
          defaultValue: '0'),
    ]
);

const Customers = SqfEntityTable(
    tableName: 'customer',
    primaryKeyName: 'id',
    primaryKeyType: PrimaryKeyType.integer_auto_incremental,
    useSoftDeleting: true,
    modelName: null,
    fields: [
      SqfEntityField('unique_id', DbType.integer, sequencedBy: customerIdentity, isUnique: true, isIndex: true),
      SqfEntityField('ref_id', DbType.integer, isUnique: true),
      SqfEntityField('business_id', DbType.integer),
      SqfEntityField('prefix', DbType.text),
      SqfEntityField('name', DbType.text),
      SqfEntityField('firstname', DbType.text),
      SqfEntityField('middleName', DbType.text),
      SqfEntityField('surname', DbType.text),
      SqfEntityField('phone', DbType.text),
      SqfEntityField('mobile', DbType.text),
      SqfEntityField('email', DbType.text),
      SqfEntityField('addressLine1', DbType.text),
      SqfEntityField('addressLine2', DbType.text),
      SqfEntityField('city', DbType.text),
      SqfEntityField('state', DbType.text),
      SqfEntityField('shippingAddress', DbType.text),
      SqfEntityField('status', DbType.text),
      SqfEntityField('custom_field1', DbType.text),
      SqfEntityField('custom_field2', DbType.text),
      SqfEntityField('custom_field3', DbType.text),
      SqfEntityField('custom_field4', DbType.text),
      SqfEntityField('dateAdded', DbType.datetimeUtc),
      SqfEntityField('dateUpdated', DbType.datetimeUtc),
      SqfEntityField('dateSynced', DbType.datetimeUtc),
      SqfEntityField('isSynced', DbType.bool, defaultValue: false),
      SqfEntityField('isActive', DbType.bool, defaultValue: true),
      SqfEntityField('isCloudActive', DbType.bool, defaultValue: true),
    ]
);

const Sales = SqfEntityTable(
    tableName: 'sale',
    primaryKeyName: 'id',
    primaryKeyType: PrimaryKeyType.integer_auto_incremental,
    useSoftDeleting: true,
    modelName: null,
    fields: [
      SqfEntityField('unique_id', DbType.integer, sequencedBy: salesIdentity, isUnique: true, isIndex: true),
      SqfEntityField('ref_id', DbType.integer, isUnique: true, isIndex: true),
      SqfEntityField('title', DbType.text),
      SqfEntityField('business_id', DbType.integer),
      SqfEntityField('amountBeforeTax', DbType.real, defaultValue: 0.0),
      SqfEntityField('taxAmount', DbType.real, defaultValue: 0.0),
      SqfEntityField('totalAmount', DbType.real, defaultValue: 0.0),
      SqfEntityField('amountReceived', DbType.real, defaultValue: 0.0),
      SqfEntityField('changeGiven', DbType.real, defaultValue: 0.0),
      SqfEntityField('discount', DbType.real, defaultValue: 0.0),
      SqfEntityField('taxLabel', DbType.text),
      SqfEntityField('discountLabel', DbType.text),
      SqfEntityField('paymentMethod', DbType.text),
      SqfEntityField('status', DbType.text),
      SqfEntityField('dateAdded', DbType.datetimeUtc),
      SqfEntityField('dateUpdated', DbType.datetimeUtc),
      SqfEntityField('dateSynced', DbType.datetimeUtc),
      SqfEntityField('isSynced', DbType.bool, defaultValue: false),
      SqfEntityField('isActive', DbType.bool, defaultValue: true),
      SqfEntityField('isCloudActive', DbType.bool, defaultValue: true),
      SqfEntityFieldRelationship(
          parentTable: Customers,
          deleteRule: DeleteRule.CASCADE,
          defaultValue: '0'),
      SqfEntityFieldRelationship(
          parentTable: Taxes,
          deleteRule: DeleteRule.CASCADE,
          defaultValue: '0'),
    ]
);

const SaleItems = SqfEntityTable(
    tableName: 'sale_item',
    primaryKeyName: 'id',
    primaryKeyType: PrimaryKeyType.integer_auto_incremental,
    useSoftDeleting: true,
    modelName: null,
    fields: [
      SqfEntityField('ref_id', DbType.integer, isUnique: true, isIndex: true),
      SqfEntityField('quantity', DbType.real),
      SqfEntityFieldRelationship(
          parentTable: Products,
          deleteRule: DeleteRule.CASCADE,
          defaultValue: '0'),
      SqfEntityFieldRelationship(
          parentTable: Sales,
          deleteRule: DeleteRule.CASCADE,
          defaultValue: '0'),
      SqfEntityFieldRelationship(
          parentTable: Variations,
          deleteRule: DeleteRule.CASCADE,
          defaultValue: '0'),
    ]
);

const Users = SqfEntityTable(
    tableName: 'user',
    primaryKeyName: 'id',
    primaryKeyType: PrimaryKeyType.integer_auto_incremental,
    useSoftDeleting: true,
    modelName: null,
    fields: [
      SqfEntityField('unique_id', DbType.integer, sequencedBy: userIdentity, isUnique: true, isIndex: true),
      SqfEntityField('ref_id', DbType.integer, isUnique: true, isIndex: true),
      SqfEntityField('username', DbType.text),
      SqfEntityField('password', DbType.text),
      SqfEntityField('access_token', DbType.text),
      SqfEntityField('refresh_token', DbType.text),
      SqfEntityField('access_token_expiry', DbType.datetimeUtc),
      SqfEntityField('firstname', DbType.text),
      SqfEntityField('surname', DbType.text),
      SqfEntityField('mobile', DbType.text),
      SqfEntityField('email', DbType.text),
      SqfEntityField('user_type', DbType.text),
      SqfEntityField('max_sales_discount_percent', DbType.real, defaultValue: 0.0),
      SqfEntityField('allow_login', DbType.text),
      SqfEntityField('status', DbType.text),
      SqfEntityField('business_name', DbType.text),
      SqfEntityField('business_id', DbType.integer),
      SqfEntityField('default_location_id', DbType.integer),
      SqfEntityField('logo', DbType.text),
      SqfEntityField('sell_price_tax', DbType.text),
      SqfEntityField('tax1_id', DbType.integer),
      SqfEntityField('tax1_label', DbType.text),
      SqfEntityField('tax1_amount', DbType.real),
      SqfEntityField('tax2_id', DbType.integer),
      SqfEntityField('tax2_label', DbType.text),
      SqfEntityField('tax2_amount', DbType.real),
      SqfEntityField('custom_field1', DbType.text),
      SqfEntityField('custom_field2', DbType.text),
      SqfEntityField('custom_field3', DbType.text),
      SqfEntityField('custom_field4', DbType.text),
      SqfEntityField('dateAdded', DbType.datetimeUtc),
      SqfEntityField('dateUpdated', DbType.datetimeUtc),
      SqfEntityField('dateSynced', DbType.datetimeUtc),
      SqfEntityField('isSynced', DbType.bool, defaultValue: false),
      SqfEntityField('isActive', DbType.bool, defaultValue: true),
      SqfEntityField('isCloudActive', DbType.bool, defaultValue: true),
    ]
);

const Locations = SqfEntityTable(
    tableName: 'location',
    primaryKeyName: 'id',
    primaryKeyType: PrimaryKeyType.integer_auto_incremental,
    useSoftDeleting: true,
    modelName: null,
    fields: [
      SqfEntityField('ref_id', DbType.integer, isUnique: true, isIndex: true),
      SqfEntityField('business_id', DbType.integer),
      SqfEntityField('location_id', DbType.text),
      SqfEntityField('name', DbType.text),
      SqfEntityField('address', DbType.text),
      SqfEntityField('country', DbType.text),
      SqfEntityField('state', DbType.text),
      SqfEntityField('city', DbType.text),
      SqfEntityField('mobile', DbType.text),
      SqfEntityField('phone', DbType.text),
      SqfEntityField('email', DbType.text),
      SqfEntityField('website', DbType.text),
      SqfEntityField('featured_products', DbType.text),
      SqfEntityField('custom_field1', DbType.text),
      SqfEntityField('custom_field2', DbType.text),
      SqfEntityField('custom_field3', DbType.text),
      SqfEntityField('custom_field4', DbType.text),
      SqfEntityField('payment_methods', DbType.text),
      SqfEntityField('dateAdded', DbType.datetimeUtc),
      SqfEntityField('dateUpdated', DbType.datetimeUtc),
      SqfEntityField('dateSynced', DbType.datetimeUtc),
      SqfEntityField('isSynced', DbType.bool, defaultValue: false),
      SqfEntityField('isActive', DbType.bool, defaultValue: true),
      SqfEntityField('isCloudActive', DbType.bool, defaultValue: true),
      SqfEntityFieldRelationship(
          parentTable: Users,
          deleteRule: DeleteRule.CASCADE,
          defaultValue: '0'),
    ]
);

const Taxes = SqfEntityTable(
    tableName: 'tax',
    primaryKeyName: 'id',
    primaryKeyType: PrimaryKeyType.integer_auto_incremental,
    useSoftDeleting: true,
    modelName: null,
    fields: [
      SqfEntityField('ref_id', DbType.integer, isIndex: true, isUnique: true),
      SqfEntityField('business_id', DbType.integer),
      SqfEntityField('name', DbType.text),
      SqfEntityField('amount', DbType.real),
      SqfEntityField('dateAdded', DbType.datetimeUtc),
      SqfEntityField('dateUpdated', DbType.datetimeUtc),
      SqfEntityField('dateSynced', DbType.datetimeUtc),
      SqfEntityField('isSynced', DbType.bool, defaultValue: false),
      SqfEntityField('isActive', DbType.bool, defaultValue: true),
      SqfEntityField('isCloudActive', DbType.bool, defaultValue: true),
      SqfEntityFieldRelationship(
          parentTable: Users,
          deleteRule: DeleteRule.CASCADE,
          defaultValue: '0'),
    ]
);

const salesIdentity = SqfEntitySequence(
      sequenceName: 'salesIdentity',
      startWith: 1101110001,
);

const productIdentity = SqfEntitySequence(
      sequenceName: 'productIdentity',
      startWith: 2101110001,
);

const customerIdentity = SqfEntitySequence(
      sequenceName: 'customerIdentity',
      startWith: 3101110001,
);

const userIdentity = SqfEntitySequence(
      sequenceName: 'userIdentity',
      startWith: 4101150001,
);

@SqfEntityBuilder(AppDbModel)
const AppDbModel = SqfEntityModel(
    modelName: 'OrbiterDbModel', // optional
    databaseName: 'OrbiterDB.db',
    databaseTables: [Products, Variations, Customers, Sales, SaleItems, Users, Locations, Taxes ],
    sequences: [salesIdentity,productIdentity, customerIdentity, userIdentity],
    bundledDatabasePath: "assets/OrbiterDB.db"
);


