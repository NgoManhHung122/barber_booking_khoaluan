const List<Map<String, dynamic>> allBarbers = [
  {
    "name": "Phill John",
    "experience": "5 years",
    "rating": 4.8,
    "image": "assets/images/barber1.png"
  },
  {
    "name": "Mike Tom",
    "experience": "3 years",
    "rating": 4.5,
    "image": "assets/images/barber2.png"
  },
  {
    "name": "Sarah Lisa",
    "experience": "7 years",
    "rating": 4.9,
    "image": "assets/images/barber3.png"
  },
  {
    "name": "David Blade",
    "experience": "4 years",
    "rating": 4.7,
    "image": "assets/images/barber4.png"
  },
  {
    "name": "Alexa Max",
    "experience": "4 years",
    "rating": 4.6,
    "image": "assets/images/barber5.png"
  },
  {
    "name": "Neymar Junior",
    "experience": "5 years",
    "rating": 4.8,
    "image": "assets/images/barber6.png"
  },
];

// Hàm tìm barber theo tên
Map<String, dynamic>? getBarberByName(String name) {
  return allBarbers.firstWhere((barber) => barber["name"] == name, orElse: () => {});
}
