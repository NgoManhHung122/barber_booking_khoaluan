// lib/services/services_data.dart

class ServicesData {
  static final List<Map<String, dynamic>> allServices = [
    {
        "title": "Classic Shaving",
        "image": "assets/images/shaving.png",
        "sub_services": [
          {"name": "Basic", "price": 10},
          {"name": "Premium (with skin care)", "price": 15},
          {"name": "VIP (premium razor + mask)", "price": 20},
        ]
      },
      {
        "title": "Hair Washing",
        "image": "assets/images/hair.png",
        "sub_services": [
          {"name": "Basic", "price": 8},
          {"name": "Premium (with head massage)", "price": 12},
          {"name": "VIP (organic shampoo)", "price": 18},
        ]
      },
      {
        "title": "Hair Cutting",
        "image": "assets/images/cutting.png",
        "sub_services": [
          {"name": "Basic", "price": 15},
          {"name": "Premium (with styling)", "price": 20},
          {"name": "VIP (styling + hair care)", "price": 30},
        ]
      },
      {
        "title": "Beard Trimming",
        "image": "assets/images/beard.png",
        "sub_services": [
          {"name": "Basic", "price": 12},
          {"name": "Premium (trimming + shaping)", "price": 18},
          {"name": "VIP (with beard oil)", "price": 25},
        ]
      },
      {
        "title": "Facials",
        "image": "assets/images/facials.png",
        "sub_services": [
          {"name": "Basic", "price": 20},
          {"name": "Premium (premium skincare)", "price": 30},
          {"name": "VIP (advanced skincare)", "price": 50},
        ]
      },
      {
        "title": "Kids Haircutting",
        "image": "assets/images/kids.png",
        "sub_services": [
          {"name": "Basic", "price": 12},
          {"name": "Premium (with styling)", "price": 18},
          {"name": "VIP (includes a gift for the child)", "price": 50},
        ]
      },
  ];
}