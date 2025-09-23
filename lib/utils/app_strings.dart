class AppStrings {
  // Home Screen
  static String appTitle(bool isBengali) => isBengali ? 'স্টক ট্র্যাকার ড্যাশবোর্ড' : 'Stock Tracker Dashboard';
  static String atGlance(bool isBengali) => isBengali ? 'এক নজরে' : 'At a Glance';
  static String totalSales(bool isBengali) => isBengali ? 'মোট বিক্রয়' : 'Total Sales';
  static String stockValue(bool isBengali) => isBengali ? 'স্টক মূল্য' : 'Stock Value';
  static String pending(bool isBengali) => isBengali ? 'অপেক্ষমান' : 'Pending';
  static String viewAllTransactions(bool isBengali) => isBengali ? 'সকল লেনদেন দেখুন' : 'View All Transactions';
  static String mainSections(bool isBengali) => isBengali ? 'প্রধান বিভাগসমূহ' : 'Main Sections';

  // Navigation Items
  static String products(bool isBengali) => isBengali ? 'পণ্যসমূহ' : 'Products';
  static String manageInventory(bool isBengali) => isBengali ? 'আপনার ইনভেন্টরি পরিচালনা করুন' : 'Manage your inventory';
  static String shops(bool isBengali) => isBengali ? 'দোকানসমূহ' : 'Shops';
  static String manageCustomers(bool isBengali) => isBengali ? 'আপনার গ্রাহকদের পরিচালনা করুন' : 'Manage your customers';
  static String deliveries(bool isBengali) => isBengali ? 'ডেলিভারি' : 'Deliveries';
  static String trackDeliveries(bool isBengali) => isBengali ? 'আপনার ডেলিভারি ট্র্যাক করুন' : 'Track your deliveries';
  static String reports(bool isBengali) => isBengali ? 'রিপোর্টসমূহ' : 'Reports';
  static String viewAnalytics(bool isBengali) => isBengali ? 'বিক্রয় ও স্টক বিশ্লেষণ দেখুন' : 'View sales and stock analytics';

  // Product List Screen
  static String productList(bool isBengali) => isBengali ? 'পণ্যের তালিকা' : 'Product List';
  static String addProduct(bool isBengali) => isBengali ? 'পণ্য যোগ করুন' : 'Add Product';
  static String searchProducts(bool isBengali) => isBengali ? 'পণ্য খুঁজুন...' : 'Search products...';
  static String noProductsFound(bool isBengali) => isBengali ? 'কোন পণ্য পাওয়া যায়নি' : 'No products found';
  static String createFirstProduct(bool isBengali) => isBengali ? 'আপনার প্রথম পণ্য তৈরি করুন' : 'Create your first product';
  static String productName(bool isBengali) => isBengali ? 'পণ্যের নাম' : 'Product Name';
  static String price(bool isBengali) => isBengali ? 'মূল্য' : 'Price';
  static String unit(bool isBengali) => isBengali ? 'একক' : 'Unit';
  static String currentStock(bool isBengali) => isBengali ? 'বর্তমান স্টক' : 'Current Stock';
  static String lowStock(bool isBengali) => isBengali ? 'কম স্টক' : 'Low Stock';
  static String outOfStock(bool isBengali) => isBengali ? 'স্টক শেষ' : 'Out of Stock';
  static String inStock(bool isBengali) => isBengali ? 'স্টক আছে' : 'In Stock';

  // Product Form Screen
  static String addNewProduct(bool isBengali) => isBengali ? 'নতুন পণ্য যোগ করুন' : 'Add New Product';
  static String editProduct(bool isBengali) => isBengali ? 'পণ্য সম্পাদনা করুন' : 'Edit Product';
  static String productNameHint(bool isBengali) => isBengali ? 'পণ্যের নাম লিখুন' : 'Enter product name';
  static String priceHint(bool isBengali) => isBengali ? 'মূল্য লিখুন' : 'Enter price';
  static String unitHint(bool isBengali) => isBengali ? 'একক (যেমন: কেজি, পিস)' : 'Unit (e.g., kg, piece)';
  static String save(bool isBengali) => isBengali ? 'সংরক্ষণ করুন' : 'Save';
  static String cancel(bool isBengali) => isBengali ? 'বাতিল' : 'Cancel';
  static String pleaseEnterProductName(bool isBengali) => isBengali ? 'দয়া করে পণ্যের নাম লিখুন' : 'Please enter product name';
  static String pleaseEnterValidPrice(bool isBengali) => isBengali ? 'দয়া করে সঠিক মূল্য লিখুন' : 'Please enter valid price';
  static String pleaseEnterUnit(bool isBengali) => isBengali ? 'দয়া করে একক লিখুন' : 'Please enter unit';

  // Shop List Screen
  static String shopList(bool isBengali) => isBengali ? 'দোকানের তালিকা' : 'Shop List';
  static String addShop(bool isBengali) => isBengali ? 'দোকান যোগ করুন' : 'Add Shop';
  static String searchShops(bool isBengali) => isBengali ? 'দোকান খুঁজুন...' : 'Search shops...';
  static String noShopsFound(bool isBengali) => isBengali ? 'কোন দোকান পাওয়া যায়নি' : 'No shops found';
  static String createFirstShop(bool isBengali) => isBengali ? 'আপনার প্রথম দোকান তৈরি করুন' : 'Create your first shop';
  static String shopName(bool isBengali) => isBengali ? 'দোকানের নাম' : 'Shop Name';
  static String ownerName(bool isBengali) => isBengali ? 'মালিকের নাম' : 'Owner Name';
  static String contact(bool isBengali) => isBengali ? 'যোগাযোগ' : 'Contact';
  static String address(bool isBengali) => isBengali ? 'ঠিকানা' : 'Address';

  // Shop Form Screen
  static String addNewShop(bool isBengali) => isBengali ? 'নতুন দোকান যোগ করুন' : 'Add New Shop';
  static String editShop(bool isBengali) => isBengali ? 'দোকান সম্পাদনা করুন' : 'Edit Shop';
  static String shopNameHint(bool isBengali) => isBengali ? 'দোকানের নাম লিখুন' : 'Enter shop name';
  static String ownerNameHint(bool isBengali) => isBengali ? 'মালিকের নাম লিখুন' : 'Enter owner name';
  static String phoneHint(bool isBengali) => isBengali ? 'ফোন নম্বর লিখুন' : 'Enter phone number';
  static String addressHint(bool isBengali) => isBengali ? 'ঠিকানা লিখুন' : 'Enter address';
  static String pleaseEnterShopName(bool isBengali) => isBengali ? 'দয়া করে দোকানের নাম লিখুন' : 'Please enter shop name';
  static String pleaseEnterOwnerName(bool isBengali) => isBengali ? 'দয়া করে মালিকের নাম লিখুন' : 'Please enter owner name';

  // Settings Screen
  static String settings(bool isBengali) => isBengali ? 'সেটিংস' : 'Settings';
  static String language(bool isBengali) => isBengali ? 'ভাষা' : 'Language';
  static String selectLanguage(bool isBengali) => isBengali ? 'ভাষা নির্বাচন করুন' : 'Select Language';
  static String english(bool isBengali) => isBengali ? 'ইংরেজি' : 'English';
  static String bengali(bool isBengali) => isBengali ? 'বাংলা' : 'বাংলা';

  // Delivery Screen
  static String deliveryList(bool isBengali) => isBengali ? 'ডেলিভারির তালিকা' : 'Delivery List';
  static String addDelivery(bool isBengali) => isBengali ? 'ডেলিভারি যোগ করুন' : 'Add Delivery';
  static String searchDeliveries(bool isBengali) => isBengali ? 'ডেলিভারি খুঁজুন...' : 'Search deliveries...';
  static String noDeliveriesFound(bool isBengali) => isBengali ? 'কোন ডেলিভারি পাওয়া যায়নি' : 'No deliveries found';
  static String createFirstDelivery(bool isBengali) => isBengali ? 'আপনার প্রথম ডেলিভারি তৈরি করুন' : 'Create your first delivery';
  static String newDelivery(bool isBengali) => isBengali ? 'নতুন ডেলিভারি' : 'New Delivery';
  static String selectShop(bool isBengali) => isBengali ? 'দোকান নির্বাচন করুন' : 'Select Shop';
  static String selectProducts(bool isBengali) => isBengali ? 'পণ্য নির্বাচন করুন' : 'Select Products';
  static String quantity(bool isBengali) => isBengali ? 'পরিমাণ' : 'Quantity';
  static String total(bool isBengali) => isBengali ? 'মোট' : 'Total';
  static String status(bool isBengali) => isBengali ? 'অবস্থা' : 'Status';
  static String completed(bool isBengali) => isBengali ? 'সম্পন্ন' : 'Completed';
  static String cancelled(bool isBengali) => isBengali ? 'বাতিল' : 'Cancelled';
  static String createDelivery(bool isBengali) => isBengali ? 'ডেলিভারি তৈরি করুন' : 'Create Delivery';

  // Stock Transaction Screen
  static String stockTransactions(bool isBengali) => isBengali ? 'স্টক লেনদেন' : 'Stock Transactions';
  static String addStock(bool isBengali) => isBengali ? 'স্টক যোগ করুন' : 'Add Stock';
  static String removeStock(bool isBengali) => isBengali ? 'স্টক কমান' : 'Remove Stock';
  static String adjustStock(bool isBengali) => isBengali ? 'স্টক সমন্বয়' : 'Adjust Stock';
  static String transactionType(bool isBengali) => isBengali ? 'লেনদেনের ধরন' : 'Transaction Type';
  static String stockIn(bool isBengali) => isBengali ? 'স্টক ইন' : 'Stock In';
  static String stockOut(bool isBengali) => isBengali ? 'স্টক আউট' : 'Stock Out';
  static String adjustment(bool isBengali) => isBengali ? 'সমন্বয়' : 'Adjustment';
  static String reason(bool isBengali) => isBengali ? 'কারণ' : 'Reason';
  static String notes(bool isBengali) => isBengali ? 'নোট' : 'Notes';
  static String date(bool isBengali) => isBengali ? 'তারিখ' : 'Date';

  // Reports Screen
  static String reportsAndAnalytics(bool isBengali) => isBengali ? 'রিপোর্ট ও বিশ্লেষণ' : 'Reports & Analytics';
  static String stockReport(bool isBengali) => isBengali ? 'স্টক রিপোর্ট' : 'Stock Report';
  static String salesReport(bool isBengali) => isBengali ? 'বিক্রয় রিপোর্ট' : 'Sales Report';
  static String shopReport(bool isBengali) => isBengali ? 'দোকান রিপোর্ট' : 'Shop Report';
  static String productReport(bool isBengali) => isBengali ? 'পণ্য রিপোর্ট' : 'Product Report';
  static String transactionReport(bool isBengali) => isBengali ? 'লেনদেন রিপোর্ট' : 'Transaction Report';
  static String analytics(bool isBengali) => isBengali ? 'বিশ্লেষণ' : 'Analytics';
  static String export(bool isBengali) => isBengali ? 'এক্সপোর্ট' : 'Export';
  static String filter(bool isBengali) => isBengali ? 'ফিল্টার' : 'Filter';
  static String fromDate(bool isBengali) => isBengali ? 'শুরুর তারিখ' : 'From Date';
  static String toDate(bool isBengali) => isBengali ? 'শেষ তারিখ' : 'To Date';

  // Detail Screens
  static String productDetails(bool isBengali) => isBengali ? 'পণ্যের বিস্তারিত' : 'Product Details';
  static String shopDetails(bool isBengali) => isBengali ? 'দোকানের বিস্তারিত' : 'Shop Details';
  static String deliveryDetails(bool isBengali) => isBengali ? 'ডেলিভারির বিস্তারিত' : 'Delivery Details';
  static String stockHistory(bool isBengali) => isBengali ? 'স্টক ইতিহাস' : 'Stock History';
  static String deliveryHistory(bool isBengali) => isBengali ? 'ডেলিভারি ইতিহাস' : 'Delivery History';
  static String lastUpdated(bool isBengali) => isBengali ? 'সর্বশেষ আপডেট' : 'Last Updated';
  static String createdOn(bool isBengali) => isBengali ? 'তৈরি হয়েছে' : 'Created On';

  // Form Labels
  static String quantityHint(bool isBengali) => isBengali ? 'পরিমাণ লিখুন' : 'Enter quantity';
  static String reasonHint(bool isBengali) => isBengali ? 'কারণ লিখুন' : 'Enter reason';
  static String notesHint(bool isBengali) => isBengali ? 'নোট লিখুন (ঐচ্ছিক)' : 'Enter notes (optional)';

  // Validation Messages
  static String pleaseEnterAddress(bool isBengali) => isBengali ? 'দয়া করে ঠিকানা লিখুন' : 'Please enter address';
  static String pleaseEnterQuantity(bool isBengali) => isBengali ? 'দয়া করে পরিমাণ লিখুন' : 'Please enter quantity';
  static String pleaseEnterValidQuantity(bool isBengali) => isBengali ? 'দয়া করে সঠিক পরিমাণ লিখুন' : 'Please enter valid quantity';
  static String pleaseSelectShop(bool isBengali) => isBengali ? 'দয়া করে একটি দোকান নির্বাচন করুন' : 'Please select a shop';
  static String pleaseSelectProduct(bool isBengali) => isBengali ? 'দয়া করে একটি পণ্য নির্বাচন করুন' : 'Please select a product';

  // Actions and Buttons
  static String markAsCompleted(bool isBengali) => isBengali ? 'সম্পন্ন হিসেবে চিহ্নিত করুন' : 'Mark as Completed';
  static String markAsCancelled(bool isBengali) => isBengali ? 'বাতিল হিসেবে চিহ্নিত করুন' : 'Mark as Cancelled';
  static String generatePDF(bool isBengali) => isBengali ? 'পিডিএফ তৈরি করুন' : 'Generate PDF';
  static String share(bool isBengali) => isBengali ? 'শেয়ার করুন' : 'Share';
  static String refresh(bool isBengali) => isBengali ? 'রিফ্রেশ' : 'Refresh';
  static String clear(bool isBengali) => isBengali ? 'পরিষ্কার' : 'Clear';
  static String apply(bool isBengali) => isBengali ? 'প্রয়োগ' : 'Apply';
  static String reset(bool isBengali) => isBengali ? 'রিসেট' : 'Reset';

  // Status Messages
  static String noDataAvailable(bool isBengali) => isBengali ? 'কোন তথ্য উপলব্ধ নেই' : 'No data available';
  static String dataExportedSuccessfully(bool isBengali) => isBengali ? 'তথ্য সফলভাবে এক্সপোর্ট হয়েছে' : 'Data exported successfully';
  static String errorExportingData(bool isBengali) => isBengali ? 'তথ্য এক্সপোর্ট করতে ত্রুটি' : 'Error exporting data';
  static String itemAddedSuccessfully(bool isBengali) => isBengali ? 'আইটেম সফলভাবে যোগ হয়েছে' : 'Item added successfully';
  static String itemUpdatedSuccessfully(bool isBengali) => isBengali ? 'আইটেম সফলভাবে আপডেট হয়েছে' : 'Item updated successfully';
  static String itemDeletedSuccessfully(bool isBengali) => isBengali ? 'আইটেম সফলভাবে মুছে ফেলা হয়েছে' : 'Item deleted successfully';

  // Common Terms
  static String ok(bool isBengali) => isBengali ? 'ঠিক আছে' : 'OK';
  static String delete(bool isBengali) => isBengali ? 'মুছে ফেলুন' : 'Delete';
  static String edit(bool isBengali) => isBengali ? 'সম্পাদনা' : 'Edit';
  static String view(bool isBengali) => isBengali ? 'দেখুন' : 'View';
  static String add(bool isBengali) => isBengali ? 'যোগ করুন' : 'Add';
  static String update(bool isBengali) => isBengali ? 'আপডেট করুন' : 'Update';
  static String loading(bool isBengali) => isBengali ? 'লোড হচ্ছে...' : 'Loading...';
  static String error(bool isBengali) => isBengali ? 'ত্রুটি' : 'Error';
  static String success(bool isBengali) => isBengali ? 'সফল' : 'Success';
}