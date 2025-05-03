import 'package:barber_booking_app/data/barber_data.dart';
import 'package:flutter/material.dart';

class Barbers extends StatefulWidget {
  @override
  _BarbersState createState() => _BarbersState();
}

class _BarbersState extends State<Barbers> {
  final TextEditingController _searchController = TextEditingController();
  List<Map<String, dynamic>> displayedBarbers = [];

  @override
  void initState() {
    super.initState();
    displayedBarbers = List.from(allBarbers);
  }

  void _filterBarbers(String query) {
    final filtered = allBarbers.where((barber) {
      final nameLower = barber['name'].toLowerCase();
      final queryLower = query.toLowerCase();
      return nameLower.contains(queryLower);
    }).toList();

    setState(() {
      displayedBarbers = filtered;
    });
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        FocusScope.of(context).unfocus();
      },
      child: Scaffold(
        backgroundColor: const Color(0xFF2b1615),
        appBar: AppBar(
          backgroundColor: const Color(0xFF2b1615),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => Navigator.of(context).pop(),
          ),
          title: const Text("Select a Barber"),
        ),
        body: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              // Search Bar
              TextField(
                controller: _searchController,
                onChanged: _filterBarbers,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: "Search barber...",
                  hintStyle: const TextStyle(color: Colors.white70),
                  prefixIcon: const Icon(Icons.search, color: Colors.white),
                  filled: true,
                  fillColor: const Color(0xFF4e2d2c),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12.0),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 20.0),
      
              // List of Barbers
              Expanded(
                child: displayedBarbers.isEmpty
                    ? const Center(
                        child: Text(
                          "No barbers found.",
                          style: TextStyle(color: Colors.white70, fontSize: 18.0),
                        ),
                      )
                    : ListView.builder(
                        itemCount: displayedBarbers.length,
                        itemBuilder: (context, index) {
                          final barber = displayedBarbers[index];
                          return GestureDetector(
                            onTap: () {
                              Navigator.pop(context, barber);
                            },
                            child: Container(
                              margin: const EdgeInsets.only(bottom: 15),
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: const Color(0xFFe29452),
                                borderRadius: BorderRadius.circular(15),
                              ),
                              child: Row(
                                children: [
                                  CircleAvatar(
                                    radius: 30,
                                    backgroundImage:
                                        barber["image"].startsWith("http")
                                            ? NetworkImage(barber["image"])
                                                as ImageProvider
                                            : AssetImage(barber["image"]),
                                  ),
                                  const SizedBox(width: 15),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          barber["name"],
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 20.0,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        Text(
                                          "${barber["experience"]} experience",
                                          style: const TextStyle(
                                            color: Colors.white70,
                                            fontSize: 16.0,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Text(
                                    "${barber["rating"]} ★",
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 18.0,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}