import 'package:flutter/material.dart';

class SubServiceSelection extends StatelessWidget {
  final List<Map<String, dynamic>> subServices;
  const SubServiceSelection({required this.subServices, super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF2b1615),
      appBar: AppBar(
        title: const Text("Select Service Package"),
        backgroundColor: const Color(0xFF2b1615),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: subServices.length,
              itemBuilder: (context, index) => Card(
                margin: const EdgeInsets.only(bottom: 15),
                color: const Color(0xFF4e2d2c),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 15,
                  ),
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.orange.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.spa, color: Colors.orange),
                  ),
                  title: Text(
                    subServices[index]['name'],
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 5),
                      Text(
                        "\$${subServices[index]['price']}",
                        style: const TextStyle(
                          color: Colors.orange,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      
                    ],
                  ),
                  trailing: const Icon(Icons.arrow_back, 
                    color: Colors.white54, 
                    size: 18
                  ),
                  onTap: () => Navigator.pop(context, subServices[index]),
                ),
              ),
            ),
          ),
          // Footer decoration
          Container(
            height: 20,
            decoration: BoxDecoration(
              color: const Color(0xFF2b1615),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.3),
                  spreadRadius: 2,
                  blurRadius: 5,
                  offset: const Offset(0, -3),
                )
              ],
            ),
          )
        ],
      ),
    );
  }
}