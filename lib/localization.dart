import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class AppLocalizations {
  final Locale locale;

  AppLocalizations(this.locale);

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static final Map<String, Map<String, String>> _localizedValues = {
    'en': {
      'line': 'line',
      'quickActions': 'Quick Actions',
      'settings': 'settings',
      'Transefer_Requests': 'Transefer Requests',
      'noProductSelected': 'No Product Selected',
      'invalidQuantity': 'Invalid Quantity',
      'username': 'Username',
      'closed_date': 'Closed Date',
      'approved_by': 'Approved By',
      'notapproved': 'Not Approved',
      'noProductsFound': 'No Products Found',
      'invoicesdetails': 'Invoices Details',
      'created_successfully': 'Created Successfully',
      'createPayment': 'Create Payment',
      'paymentCreatedSuccess': 'payment Created Successfully',
      'paymentError': 'payment Error',
      'immediatePayment': 'immediate',
      'Immediate': 'Immediate',
      'invoices': 'invoices',
      'reverse_invoice': 'Reverse Invoice',
      'reverse_invoice_reason': 'Reason for Reversal',
      'reverse_invoice_date': 'Reversal Date',
      'reverse_invoice_success': 'Invoice reversed successfully',
      'reverse_invoice_error': 'Error reversing invoice',
      'edit_reversed_invoice': 'Edit Reversed Invoice',
      'save_changes': 'Save Changes',
      'post_invoice': 'Post Invoice',
      'save_and_post': 'Save & Post',
      'update_success': 'Invoice updated successfully',
      'post_success': 'Invoice posted successfully',
      'retry': 'Retry',
      'sales_Order_details': 'Sales order details',
      'no_tax_applied': 'No taxes applied',
      'sales': 'Sales',
      'subtotal': 'subtotal',
      'total': 'total',
      'discount': 'discount',
      "delivered": "delivered",
      'pricelist': 'pricelist',
      'date': 'Date',
      'invoiced': 'invoiced',
      'price': 'price',
      'upselling_opportunity': 'Upselling Opportunity',
      'fully_invoiced': 'Fully Invoiced',
      'to_invoice': 'To Invoice',
      'nothing_to_invoice': 'Nothing To Invoice',
      'delivery_order_details': 'Delivery Order Details',
      'loading_order_details': 'Loading order details...',
      'error_loading_order': 'Error loading order:',
      'not_available': 'N/A',
      'scheduled_date': 'Scheduled Date',
      'create_date': 'Create Date',
      'deadline': 'Deadline',
      'source_document': 'Source Document',
      'operation_type': 'Operation Type',
      'products': 'Products',
      'unknown_product': 'Unknown Product',
      'unit': 'Unit',
      'demand': 'Demand',
      'quantity_label': 'Quantity',
      'validate_order': 'Validate Order',
      'create_backorder': 'Create Backorder',
      'validate_without_backorder_action': 'Validate Without Backorder',
      'order_validated_successfully': 'Order validated successfully!',
      'order_cannot_be_validated':
          'Order cannot be validated in its current state',
      'password': 'Password',
      'login': 'LOGIN',
      'forgotPassword': 'Forgot Password?',
      'signUp': 'Sign Up',
      'usernameRequired': 'Please enter your username',
      'passwordRequired': 'Please enter your password',
      'title': 'Welcome',
      "home_title": "Home",
      "welcome_text": "Welcome",
      "order": "Order",
      "delivery_order": "Delivery Order",
      "inventory_receipts": "Inventory Receipts",
      "inventory_receipts_details": "Inventory Receipts Details",
      "stock_picking_requests": "Transfer Request",
      "stock_picking_request_details": "Stock Picking Request Details",
      "logout": "Logout",
      'customer': 'Customer',
      'payment_terms': 'Payment Terms',
      'order_lines': 'Order Lines',
      'add_line': 'Add Line',
      'product': 'Product',
      'available_quantity': 'Available Quantity',
      'quantity': 'Quantity',
      'unit_price': 'Unit Price',
      'taxes': 'Taxes',
      'tax': 'Tax',
      'total_price_with_tax': 'Total Price with Tax',
      'total_price': 'Total Price',
      'total_price_with_taxes': 'Total Price with Taxes',
      'save': 'Save',
      'choose_action': 'Choose Action',
      'create_confirm_sales_order': 'Create & Confirm Sales Order',
      'create_confirm_delivery_order': 'Create & Confirm Delivery Order',
      'create_inventory_receipt': 'Create Inventory Receipt',
      'no_customers_found': 'No customers found',
      'no_payment_terms_found': 'No payment terms found',
      'no_products_found': 'No products found',
      'select': 'Select',
      'warehouse': 'Warehouse',
      'Please_select_a_customer_and_payment_term':
          'Please select a customer and payment term',
      'delivery_orders': 'Delivery Orders',
      'search': 'Search',
      'filter': 'Filter',
      'new': 'New',
      'load_more': 'Load More',
      'no_orders_found': 'No orders found',
      'no_matching_orders_found': 'No matching orders found',
      'clear': 'Clear',
      'back': 'Back',
      'unknown_customer': 'Unknown Customer',
      'reference': 'Reference',
      'scheduled': 'Scheduled',
      'items': 'Items',
      'Delivered': 'Delivered',
      'draft': 'Draft',
      'ready': 'Ready',
      'done_status': 'Done',
      'waiting': 'Waiting',
      'canceled': 'Canceled',
      'confirmed': 'Confirmed',
      'cancelled': 'Cancelled',
      'all': 'All',
      'cancel': 'Cancel',
      'unknown': 'unknown',
      'receipt_lines': 'Receipt Lines',
      'select_customer_and_lines':
          'Please select a customer and add order lines',
      'invalid_order_line': 'Invalid order line',
      'order_created': 'Order created',
      'no_stock_picking_requests': 'No stock picking requests found',
      'try_again': 'Try Again',
      'origin': 'Origin',
      'source_location': 'Source Location',
      'destination_location': 'Destination Location',
      'check_availability': 'Check Availability',
      'validate': 'Validate',
      'validation_options': 'Validation Options',
      'validate_with_backorder': 'Validate with Backorder',
      'validate_with_backorder_description':
          'Create a backorder for unprocessed products',
      'validate_without_backorder': 'Validate without Backorder',
      'validate_without_backorder_description':
          'Process only available products and cancel the rest',
      'validation_success': 'Validation successful',
      'validation_without_backorder_success':
          'Validation without backorder successful',
      'done': 'Done',
      'Requested_By': 'Requested By',
      'add_product_line': 'Add Line',
      'remove_line': 'Remove Line',
      'confirm_deletion': 'Confirm Deletion',
      'confirm_remove_product':
          'Are you sure you want to remove "%s" from this request?',
      'remove': 'Remove',
      'product_line_added': 'Product line added successfully',
      'product_line_removed': 'Product line removed successfully',
      'quantity_to_transfer': 'Quantity to Transfer',
      'product_code': 'Product Code',
      'select_product': 'Select Product',
      'product_details': 'Product Details',
      'returns_created_and_validated':
          'Returns created and validated successfully',
    },
    'ar': {
      'line': 'الطلب',
      'quickActions': "الإجراءات السريعة",
      'settings': 'الإعدادات',
      'Transefer_Requests': 'طلب تحويل',
      'invalidQuantity': 'كميه غير صالحه',
      'noProductSelected': 'لم يتم اختياؤ منتج',
      'approved_by': 'تمت الموافقة من قبل',
      'closed_date': 'تاريخ الإغلاق',
      'notapproved': 'غير معتمد',
      'upselling_opportunity': 'فرصه الارتقاء بالصفقه',
      'noProductsFound': 'لم يتم العثور على منتجات',
      'invoicesdetails': 'تفاصيل الفتورة',
      'created_successfully': 'تم الإنشاء بنجاح',
      'paymentCreatedSuccess': 'تم انشاء الدفع بنجاح',
      'immediatePayment': 'فوري',
      'createPayment': 'إنشاء دفع',
      'paymentError': 'خطأ في الدفع',
      'invoices': 'الفواتير',
      'reverse_invoice': 'عكس الفاتورة',
      'reverse_invoice_reason': 'سبب العكس',
      'reverse_invoice_date': 'تاريخ العكس',
      'reverse_invoice_success': 'تم عكس الفاتورة بنجاح',
      'reverse_invoice_error': 'خطأ في عكس الفاتورة',
      'edit_reversed_invoice': 'تعديل الفاتورة المعكوسة',
      'save_changes': 'حفظ التغييرات',
      'post_invoice': 'ترحيل الفاتورة',
      'save_and_post': 'حفظ وترحيل',
      'update_success': 'تم تحديث الفاتورة بنجاح',
      'post_success': 'تم ترحيل الفاتورة بنجاح',
      'retry': 'اعد المحاوله',
      'sales_Order_details': 'تفاصيل طلب المبيعات',
      'no_tax_applied': 'لا يوجد ضرا]ب مضافه',
      'sales': 'المندوب',
      'subtotal': 'المجموع الفرعي',
      'total': 'المجموع',
      'discount': 'الخصم',
      "delivered": "تم التسليم",
      'Delivered': 'تم التوصيل',
      'price': 'السعر',
      'invoiced': 'مفوتر',
      'fully_invoiced': 'مفوتره بالكامل',
      'to_invoice': 'بانتظار الفوتره',
      'nothing_to_invoice': 'لا توجد مبالغ افوترتها',
      'delivery_order_details': 'تفاصيل أمر التوصيل',
      'loading_order_details': 'جاري تحميل تفاصيل الطلب...',
      'error_loading_order': 'خطأ في تحميل الطلب:',
      'not_available': 'غير متاح',
      'scheduled_date': 'التاريخ المحدد',
      'create_date': 'تاريخ الإنشاء',
      'pricelist': 'قائمة الأسعار',
      'date': 'التاريخ',
      'deadline': 'الموعد النهائي',
      'source_document': 'المستند المصدر',
      'operation_type': 'نوع العملية',
      'products': 'المنتجات',
      'unknown_product': 'منتج غير معروف',
      'unit': 'الوحدة',
      'demand': 'الطلب',
      'quantity': 'الكمية',
      'validate_order': 'تحقق من الطلب',
      'create_backorder': 'إنشاء طلب مؤجل',
      'validate_without_backorder': 'تحقق بدون طلب مؤجل',
      'order_validated_successfully': 'تم التحقق من الطلب بنجاح!',
      'order_cannot_be_validated': 'لا يمكن التحقق من الطلب في حالته الحالية',
      'username': 'اسم المستخدم',
      'password': 'كلمة المرور',
      'login': 'تسجيل الدخول',
      'forgotPassword': 'هل نسيت كلمة المرور؟',
      'signUp': 'إنشاء حساب',
      'usernameRequired': 'الرجاء إدخال اسم المستخدم',
      'passwordRequired': 'الرجاء إدخال كلمة المرور',
      'title': 'مرحبا',
      "home_title": "الرئيسية",
      "welcome_text": "مرحبًا",
      "order": "الطلبات",
      "delivery_order": "أمر التوصيل",
      "inventory_receipts": "إيصالات المخزون",
      "inventory_receipts_details": "تفاصيل إيصالات المخزون",
      "stock_picking_requests": "طلب تحويل",
      "stock_picking_request_details": "تفاصيل طلب نقل المخزون",
      "logout": "تسجيل خروج",
      'customer': 'العميل',
      'payment_terms': 'شروط الدفع',
      'order_lines': 'بنود الطلب',
      'add_line': 'إضافة منتج',
      'product': 'المنتج',
      'available_quantity': 'الكمية المتاحة',
      'unit_price': 'سعر الوحدة',
      'taxes': 'الضرائب',
      'tax': 'الضريبة',
      'total_price_with_tax': 'السعر الإجمالي مع الضريبة',
      'total_price': 'السعر الإجمالي',
      'total_price_with_taxes': 'السعر الإجمالي مع الضرائب',
      'save': 'حفظ',
      'choose_action': 'اختر إجراء',
      'create_confirm_sales_order': 'إنشاء وتأكيد أمر المبيعات',
      'order_created': 'تم انشاء أمر المبيعات',
      'create_confirm_delivery_order': 'إنشاء وتأكيد أمر التسليم',
      'create_inventory_receipt': 'إنشاء إيصال مخزون',
      'no_customers_found': 'لم يتم العثور على عملاء',
      'no_payment_terms_found': 'لم يتم العثور على شروط دفع',
      'no_products_found': 'لم يتم العثور على منتجات',
      'select': 'اختر',
      'Please_select_a_customer_and_payment_term':
          'الرجاء تحديد عميل وشروط دفع',
      'delivery_orders': 'أوامر التوصيل',
      'search': 'بحث',
      'filter': 'تصفية',
      'new': 'جديد',
      'load_more': 'تحميل المزيد',
      'no_orders_found': 'لم يتم العثور على أوامر',
      'no_matching_orders_found': 'لم يتم العثور على أوامر مطابقة',
      'clear': 'مسح',
      'back': 'رجوع',
      'unknown_customer': 'عميل غير معروف',
      'reference': 'المرجع',
      'scheduled': 'مجدول',
      'items': 'العناصر',
      'draft': 'مسودة',
      'ready': 'جاهز',
      'done_status': 'مكتمل',
      'waiting': 'في الانتظار',
      'canceled': 'ملغى',
      'confirmed': 'مؤكد',
      'cancelled': 'ملغي',
      'all': 'الكل',
      'cancel': 'إلغاء',
      'unknown': 'غير معروف',
      'receipt_lines': 'بنود الإيصال',
      'select_customer_and_lines': 'الرجاء تحديد عميل وإضافة بنود الطلب',
      'invalid_order_line': 'بند طلب غير صالح',
      'Immediate': 'فوري',
      'no_stock_picking_requests': 'لم يتم العثور على طلبات نقل المخزون',
      'try_again': 'حاول مرة أخرى',
      'origin': 'المصدر',
      'source_location': 'موقع المصدر',
      'destination_location': 'موقع الوجهة',
      'check_availability': 'التحقق من التوفر',
      'validate': 'تحقق',
      'validation_options': 'خيارات التحقق',
      'validate_with_backorder': 'تحقق مع طلب مؤجل',
      'validate_with_backorder_description':
          'إنشاء طلب مؤجل للمنتجات غير المعالجة',
      'validate_without_backorder_action': 'تحقق بدون طلب مؤجل',
      'validate_without_backorder_description':
          'معالجة المنتجات المتوفرة فقط وإلغاء الباقي',
      'validation_success': 'تم التحقق بنجاح',
      'warehouse': 'المخزن',
      'validation_without_backorder_success': 'تم التحقق بدون طلب مؤجل بنجاح',
      'add_product_line': 'إضافة منتج',
      'remove_line': 'إزالة المنتج',
      'Requested_By': 'طلب من قبل',
      'confirm_deletion': 'تأكيد الحذف',
      'confirm_remove_product':
          'هل أنت متأكد أنك تريد إزالة "%s" من هذا الطلب؟',
      'remove': 'إزالة',
      'product_line_added': 'تمت إضافة المنتج بنجاح',
      'product_line_removed': 'تمت إزالة المنتج بنجاح',
      'quantity_to_transfer': 'الكمية المراد نقلها',
      'product_code': 'رمز المنتج',
      'select_product': 'اختر منتج',
      'product_details': 'تفاصيل المنتج',
    },
  };

  String _translate(String key) {
    // Get the translations for the current locale
    final translations = _localizedValues[locale.languageCode];

    // If the key is not found, return the key itself as a fallback
    return translations?[key] ?? key;
  }

  // Getters for translations
  String get username => _translate('username');
  String get quickActions => _translate('quickActions');
  String get settings => _translate('settings');
  String get line => _translate('line');
  String get noProductSelected => _translate('noProductSelected');
  String get approved_by => _translate('approved_by');
  String get notapproved => _translate('notapproved');
  String get noProductsFound => _translate('noProductsFound');
  String get created_successfully => _translate('created_successfully');
  String get paymentError => _translate('paymentError');
  String get createPayment => _translate('createPayment');
  String get paymentCreatedSuccess => _translate('paymentCreatedSuccess');
  String get immediate => _translate('immediatePayment');
  String get invoices => _translate('invoices');
  String get invalidQuantity => _translate('invalidQuantity');
  String get invoicesdetails => _translate('invoicesdetails');
  String get retry => _translate('retry');
  String get reverse_invoice => _translate('reverse_invoice');
  String get reverse_invoice_reason => _translate('reverse_invoice_reason');
  String get reverse_invoice_date => _translate('reverse_invoice_date');
  String get reverse_invoice_success => _translate('reverse_invoice_success');
  String get reverse_invoice_error => _translate('reverse_invoice_error');
  String get edit_reversed_invoice => _translate('edit_reversed_invoice');
  String get save_changes => _translate('save_changes');
  String get post_invoice => _translate('post_invoice');
  String get save_and_post => _translate('save_and_post');
  String get update_success => _translate('update_success');
  String get post_success => _translate('post_success');
  String get no_tax_applied => _translate('no_tax_applied');
  String get sales => _translate('sales');
  String get total => _translate('total');
  String get discount => _translate('discount');
  String get subtotal => _translate('subtotal');
  String get Delivered => _translate('Delivered');
  String get price => _translate('price');
  String get date => _translate('date');
  String get pricelist => _translate('pricelist');
  String get invoiced => _translate('invoiced');
  String get upselling_opportunity => _translate('upselling_opportunity');
  String get fully_invoiced => _translate('fully_invoiced');
  String get to_invoice => _translate('to_invoice');
  String get nothing_to_invoice => _translate('nothing_to_invoice');
  String get deliveryOrderDetails => _translate('delivery_order_details');
  String get loadingOrderDetails => _translate('loading_order_details');
  String get errorLoadingOrder => _translate('error_loading_order');
  String get notAvailable => _translate('not_available');
  String get scheduledDate => _translate('scheduled_date');
  String get create_date => _translate('create_date');
  String get deadline => _translate('deadline');
  String get sourceDocument => _translate('source_document');
  String get Immediate => _translate('Immediate');
  String get operationType => _translate('operation_type');
  String get products => _translate('products');
  String get unknownProduct => _translate('unknown_product');
  String get unit => _translate('unit');
  String get demand => _translate('demand');
  String get validateOrder => _translate('validate_order');
  String get createBackorder => _translate('create_backorder');
  String get validateWithoutBackorder =>
      _translate('validate_without_backorder');
  String get orderValidatedSuccessfully =>
      _translate('order_validated_successfully');
  String get orderCannotBeValidated => _translate('order_cannot_be_validated');
  String get order_created => _translate('order_created');
  String get receipt_lines => _translate('receipt_lines');
  String get closed_date => _translate('closed_date');
  String get select_customer_and_lines =>
      _translate('select_customer_and_lines');
  String get invalid_order_line => _translate('invalid_order_line');
  String get delivery_orders => _translate('delivery_orders');
  String get search => _translate('search');
  String get filter => _translate('filter');
  String get unknown => _translate('unknown');
  String get new_order => _translate('new');
  String get load_more => _translate('load_more');
  String get no_orders_found => _translate('no_orders_found');
  String get no_matching_orders_found => _translate('no_matching_orders_found');
  String get clear => _translate('clear');
  String get back => _translate('back');
  String get password => _translate('password');
  String get login => _translate('login');
  String get forgotPassword => _translate('forgotPassword');
  String get signUp => _translate('signUp');
  String get usernameRequired => _translate('usernameRequired');
  String get passwordRequired => _translate('passwordRequired');
  String get title => _translate('title');
  String get homeTitle => _translate('home_title');
  String get welcomeText => _translate('welcome_text');
  String get order => _translate('order');
  String get deliveryOrder => _translate('delivery_order');
  String get inventoryReceipts => _translate('inventory_receipts');
  String get inventory_receipts_details =>
      _translate('inventory_receipts_details');
  String get salesOrderDetails => _translate('sales_Order_details');
  String get logout => _translate('logout');
  String get customer => _translate('customer');
  String get payment_terms => _translate('payment_terms');
  String get order_lines => _translate('order_lines');
  String get add_line => _translate('add_line');
  String get product => _translate('product');
  String get available_quantity => _translate('available_quantity');
  String get quantity => _translate('quantity');
  String get unit_price => _translate('unit_price');
  String get taxes => _translate('taxes');
  String get tax => _translate('tax');
  String get total_price_with_tax => _translate('total_price_with_tax');
  String get total_price => _translate('total_price');
  String get total_price_with_taxes => _translate('total_price_with_taxes');
  String get save => _translate('save');
  String get choose_action => _translate('choose_action');
  String get create_confirm_sales_order =>
      _translate('create_confirm_sales_order');
  String get create_confirm_delivery_order =>
      _translate('create_confirm_delivery_order');
  String get create_inventory_receipt => _translate('create_inventory_receipt');
  String get no_customers_found => _translate('no_customers_found');
  String get no_payment_terms_found => _translate('no_payment_terms_found');
  String get no_products_found => _translate('no_products_found');
  String get Please_select_a_customer_and_payment_term =>
      _translate('Please_select_a_customer_and_payment_term');
  String get unknown_customer => _translate('unknown_customer');
  String get reference => _translate('reference');
  String get scheduled => _translate('scheduled');
  String get items => _translate('items');
  String get draft => _translate('draft');
  String get ready => _translate('ready');
  String get done => _translate('done_status');
  String get waiting => _translate('waiting');
  String get canceled => _translate('canceled');
  String get confirmed => _translate('confirmed');
  String get cancelled => _translate('cancelled');
  String get all => _translate('all');
  String get cancel => _translate('cancel');
  String get select => _translate('select');
  String get stockPickingRequests => _translate('stock_picking_requests');
  String get Transefer_Requests => _translate('Transefer Requests');
  String get noStockPickingRequests => _translate('no_stock_picking_requests');
  String get tryAgain => _translate('try_again');
  String get origin => _translate('origin');
  String get warehouse => _translate('warehouse');
  String get sourceLocation => _translate('source_location');
  String get destinationLocation => _translate('destination_location');
  String get requested_by => _translate('Requested_By');
  String get checkAvailability => _translate('check_availability');
  String get validate => _translate('validate');
  String get validationOptions => _translate('validation_options');
  String get validateWithBackorder => _translate('validate_with_backorder');
  String get validateWithBackorderDescription =>
      _translate('validate_with_backorder_description');
  String get validateWithoutBackorderOption =>
      _translate('validate_without_backorder');
  String get validateWithoutBackorderDescription =>
      _translate('validate_without_backorder_description');
  String get validationSuccess => _translate('validation_success');
  String get validationWithoutBackorderSuccess =>
      _translate('validation_without_backorder_success');
  String get addProductLine => _translate('add_product_line');
  String get removeLine => _translate('remove_line');
  String get confirmDeletion => _translate('confirm_deletion');
  String get confirmRemoveProduct => _translate('confirm_remove_product');
  String get remove => _translate('remove');
  String get productLineAdded => _translate('product_line_added');
  String get productLineRemoved => _translate('product_line_removed');
  String get quantityToTransfer => _translate('quantity_to_transfer');
  String get productCode => _translate('product_code');
  String get selectProduct => _translate('select_product');
  String get productDetails => _translate('product_details');
  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) {
    // Only support 'en' and 'ar' languages
    return ['en', 'ar'].contains(locale.languageCode);
  }

  @override
  Future<AppLocalizations> load(Locale locale) async {
    return AppLocalizations(locale);
  }

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}
