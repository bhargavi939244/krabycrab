import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart'; // Import geolocator
import 'package:geocoding/geocoding.dart'; // Import geocoding
import 'package:url_launcher/url_launcher.dart';
import 'cart_badge_icon.dart';
import 'dinein_form.dart';
import 'offers.dart';
import 'menu_page.dart';
import 'profile_page.dart';
import 'addlocation.dart';
import 'bestseller.dart';
import 'aboutme_page.dart';
import 'orders_page.dart';
// import 'checkout_page.dart';
import 'user_details_page.dart';
import 'login_page.dart';
import 'cart_page.dart';
import 'global.dart' as globals;
import 'auth_wrapper.dart';
import 'package:firebase_auth/firebase_auth.dart'; // Import firebase auth

class Homepage extends StatefulWidget {
  final Map<String, dynamic> userData;

  const Homepage({Key? key, required this.userData}) : super(key: key);
  
  @override
  _HomepageState createState() => _HomepageState();
}

class _HomepageState extends State<Homepage> {
  int selectedOption = 0;
  String selectedLocationOrStore = "Fetching location...";

  Position? _currentPosition;
  String _currentAddress = "Unknown Location";

  @override
  void initState() {
    super.initState();
    _getCurrentPosition();
  }

  // A method to handle logout
  void _logout() async {
    await FirebaseAuth.instance.signOut();
  }

  Future<bool> _handleLocationPermission() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text(
              'Location services are disabled. Please enable the services')));
      return false;
    }
    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Location permissions are denied')));
        return false;
      }
    }
    if (permission == LocationPermission.deniedForever) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text(
              'Location permissions are permanently denied, we cannot request permissions.')));
      return false;
    }
    return true;
  }

  Future<void> _getCurrentPosition() async {
    final hasPermission = await _handleLocationPermission();
    if (!hasPermission) return;
    try {
      Position position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high);
      _currentPosition = position;
      _getAddressFromLatLng(position);
    } catch (e) {
      debugPrint(e.toString());
      setState(() {
        selectedLocationOrStore = "Failed to get location";
      });
    }
  }

  Future<void> _getAddressFromLatLng(Position position) async {
    try {
      List<Placemark> placemarks =
          await placemarkFromCoordinates(position.latitude, position.longitude);
      Placemark place = placemarks[0];
      setState(() {
        _currentAddress =
            '${place.street}, ${place.locality}, ${place.administrativeArea}';
        selectedLocationOrStore = _currentAddress;
      });
    } catch (e) {
      debugPrint(e.toString());
      setState(() {
        _currentAddress = "Unknown Address";
        selectedLocationOrStore = _currentAddress;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // Get the current user from Firebase Auth
    final user = FirebaseAuth.instance.currentUser;
    final bool isLoggedIn = user != null;

    return Scaffold(
      drawer: Drawer(
        backgroundColor: Colors.white,
        child: ListView(
          padding: EdgeInsets.zero,
          children: <Widget>[
            const DrawerHeader(
              decoration: BoxDecoration(color: Colors.red),
              child: Text('Welcome to KrabyCrab!',
                  style: TextStyle(color: Colors.white, fontSize: 20)),
            ),
            Align(
              alignment: Alignment.topRight,
              child: IconButton(
                icon: const Icon(Icons.close, color: Colors.white),
                onPressed: () {
                  Navigator.pop(context); // Closes the drawer
                },
              ),
            ),
            // Conditionally show Login or Logout based on user state
            if (!isLoggedIn)
              ListTile(
                leading: const Icon(Icons.person),
                title: const Text('Login'),
                onTap: () {
                  Navigator.push(context,
                      MaterialPageRoute(builder: (context) =>  LoginPage()));
                },
              )
            else
              ListTile(
                leading: const Icon(Icons.logout),
                title: const Text('Logout'),
                onTap: () => _logout(),
              ),
            ListTile(
              leading: const Icon(Icons.restaurant_menu),
              title: const Text('Menu'),
              onTap: () {
                Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => MenuPage(
                            initialSection: 'Snow Crab Deal',
                            selectedStore: selectedOption == 0 ? null : selectedLocationOrStore,
                            )));
              },
            ),
            ListTile(
              leading: const Icon(Icons.shopping_cart),
              title: const Text('Cart'),
              onTap: () {
                Navigator.push(context,
                    MaterialPageRoute(builder: (context) => const CartPage(cartItems: [],)));
              },
            ),
            ListTile(
              leading: const Icon(Icons.person),
              title: const Text('About Me'),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => AboutmePage(userData: widget.userData),
                  ),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.assignment),
              title: const Text('Orders'),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                     builder: (context) => const OrdersPage()),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.local_offer),
              title: const Text('Offers'),
              onTap: () {
                Navigator.push(context,
                    MaterialPageRoute(builder: (context) =>  OffersPage()));
              },
            ),
            ListTile(
              leading: const Icon(Icons.location_on),
              title: const Text('Add Location'),
              onTap: () {
                Navigator.push(context,
                    MaterialPageRoute(builder: (context) =>  AddLocationPage()));
              },
            ),
            const Divider(),
          ],
        ),
      ),
      backgroundColor: Colors.blue[50],
      appBar: AppBar(
        backgroundColor: const Color.fromARGB(255, 189, 4, 4),
        title: Column(
          children: [
            Row(
              children: [
                Text(
                  selectedOption == 0
                      ? "Deliver to"
                      : selectedOption == 1
                          ? "Take Away from"
                          : "Dine In",
                  style: const TextStyle(fontSize: 18, color: Colors.white),
                ),
                const Padding(
                  padding: EdgeInsets.only(left: 8.0),
                ),
              ],
            ),
            Align(
              alignment: Alignment.topLeft,
              child: Text(
                selectedLocationOrStore,
                style: const TextStyle(fontSize: 14, color: Colors.white),
              ),
            ),
          ],
        ),
        actions: const [
          CartBadgeIcon(),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    color: Colors.white,
                    child: Row(
                      children: [
                        Radio(
                          value: 0,
                          groupValue: selectedOption,
                          onChanged: (value) {
                            setState(() {
                              selectedOption = value as int;
                              // Update location for delivery with current address
                              selectedLocationOrStore = _currentAddress;
                            });
                          },
                        ),
                        const Text("Delivery"),
                        Radio(
                          value: 1,
                          groupValue: selectedOption,
                          onChanged: (value) {
                            setState(() {
                              selectedOption = value as int;
                              selectedLocationOrStore =
                                  "107 N Nebraska Ave, Tampa, FL 33604"; // Initial store for takeaway
                            });
                          },
                        ),
                        const Text("Take Away"),
                        Radio(
  value: 2,
  groupValue: selectedOption,
  onChanged: (value) {
    setState(() {
      selectedOption = value as int;
      selectedLocationOrStore =
          "107 N Nebraska Ave, Tampa, FL 33604"; // Initial store for dine in

      // Add navigation logic here
      if (selectedOption == 2) {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => DineInForm()),
        );
      }
    });
  },
),
                        const Text("Dine In"),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),
                  if (selectedOption == 0) ...[
                    Container(
                      padding: const EdgeInsets.all(10),
                      color: Colors.white,
                      child: Row(
                        children: [
                          const Icon(Icons.location_on, color: Colors.red),
                          const SizedBox(width: 8),
                          Text("Delivering to: $selectedLocationOrStore",
                              style: const TextStyle(fontSize: 16)),
                          const Spacer(),
                          TextButton(
                            onPressed: () {
                              Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                      builder: (_) =>  AddLocationPage()));
                            },
                            child: const Text("Change"),
                          )
                        ],
                      ),
                    )
                  ] else if (selectedOption == 1 || selectedOption == 2) ...[
                    storeInfoSection(),
                  ]
                ],
              ),
            ),
            Container(
              height: 150,
              width: MediaQuery.of(context).size.height - 185.0,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: [
                  bannerlist("assets/cover1.jpg"),
                  bannerlist("assets/cover3.jpg"),
                  bannerlist("assets/rs=w_2320,h_1740 (1).webp"),
                  bannerlist("assets/rs=w_2320,h_1740.webp"),
                ],
              ),
            ),
            sectionTitle("Explore Menu"),
            menuRows(),
            const SizedBox(height: 30),
            Container(
              height: 200,
              width: MediaQuery.of(context).size.width,
              child: Image.asset("assets/bannerfotter.jpg", fit: BoxFit.cover),
            ),
            const SizedBox(height: 30),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                sectionTitle("Offers", paddingLeft: 20),
                GestureDetector(
                  onTap: () {
                    Navigator.push(context,
                        MaterialPageRoute(builder: (context) =>  OffersPage()));
                  },
                  child: const Padding(
                    padding: EdgeInsets.only(right: 20),
                    child: Text("VIEW ALL",
                        style: TextStyle(
                            color: Colors.blue,
                            fontWeight: FontWeight.bold,
                            fontSize: 16)),
                  ),
                )
              ],
            ),
            Container(
              height: 200,
              padding: const EdgeInsets.symmetric(horizontal: 10),
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: [
                  bannerlist("assets/cover2.jpg"),
                  bannerlist("assets/snowcrab.jpg"),
                  bannerlist("assets/cover1.jpg"),
                ],
              ),
            ),
            sectionTitle("Bestsellers", paddingLeft: 20),
            SizedBox(
              height: 250,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: [
                  bestseller("Crab", "assets/cover2.jpg", "\$ 29.99",
                      "Medium"),
                  bestseller("Wings", "assets/rs=w_2320,h_1740.webp", "\$ 19.99",
                      "Regular"),
                  bestseller("Snow Crab", "assets/rs=w_1342,cg_true,m.webp", "\$ 10.99", "Large"),
                ],
              ),
            ),
            const SizedBox(height: 100),
          ],
        ),
      ),
    );
  }

  Widget sectionTitle(String title, {double paddingLeft = 22}) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Padding(
        padding: EdgeInsets.only(left: paddingLeft, top: 20),
        child: Text(title,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20)),
      ),
    );
  }

  Widget menuRows() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10),
          child: Row(
            children: [
              Expanded(
                  child: menuCard("assets/snowcrab.jpg", "Snow Crab Deals",
                      section: "Snow Crab Deals")),
              const SizedBox(width: 10),
              Expanded(
                  child: menuCard("assets/bluecrab.jpg", "Blue Crab Meals",
                      section: "Blue Crab Meals")),
            ],
          ),
        ),
        const SizedBox(height: 10),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10),
          child: Row(
            children: [
              Expanded(
                  child: menuCard("assets/wings.jpg", "Fried Wings",
                      height: 130, section: "Kraby Sandwiches")),
              const SizedBox(width: 10),
              Expanded(
                  child: menuCard("assets/colddrinks.webp", "Beverages",
                      height: 130, section: "Soups")),
              const SizedBox(width: 10),
              Expanded(
                  child: menuCard("assets/sandwich.jpg", "Sandwiches",
                      height: 130, section: "Kraby Sandwiches")),
            ],
          ),
        ),
      ],
    );
  }

  Widget menuCard(String img, String label,
      {double height = 200, double width = 200, String? section}) {
    return InkWell(
      onTap: () {
        if (section != null) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => MenuPage(
                initialSection: section,
                selectedStore: selectedOption == 0 ? null : selectedLocationOrStore,
              ),
            ),
          );
        }
      },
      child: Container(
        height: height,
        width: width,
        decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8), color: Colors.white),
        child: Column(
          children: [
            const SizedBox(height: 10),
            Image.asset(img, height: height - 70),
            const SizedBox(height: 10),
            Text(label,
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
          ],
        ),
      ),
    );
  }

  Widget storeInfoSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          margin: const EdgeInsets.symmetric(vertical: 10),
          padding: const EdgeInsets.all(10),
          color: Colors.white,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text("Available Stores:",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),
              storeCard(
                "107 N Nebraska Ave, Tampa, FL 33604",
                "813-238-8100",
              ),
              const SizedBox(height: 10),
              storeCard(
                "2030 E Fletcher Ave, Tampa, FL 33612",
                "813-238-8101",
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget storeCard(String address, String phone) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        border: Border.all(color: Colors.grey),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.store, color: Colors.red),
              const SizedBox(width: 8),
              Expanded(child: Text(address, style: const TextStyle(fontSize: 14))),
            ],
          ),
          const SizedBox(height: 5),
          Row(
            children: [
              const Icon(Icons.phone, size: 16, color: Colors.green),
              const SizedBox(width: 8),
              Text(phone),
            ],
          ),
          const SizedBox(height: 10),
          Align(
            alignment: Alignment.centerRight,
            child: ElevatedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => MenuPage(
                      initialSection: "Snow Crab Deals",
                      selectedStore: address,
                    ),
                  ),
                );
              },
              icon: const Icon(Icons.restaurant),
              label: const Text("Order from here"),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  // Best seller widget definition
  Widget bestseller(String name, String image, String price, String size) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 10),
      width: 150,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.5),
            spreadRadius: 1,
            blurRadius: 5,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Image.asset(
            image,
            height: 100,
            width: double.infinity,
            fit: BoxFit.cover,
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                const SizedBox(height: 4),
                Text(
                  "Size: $size",
                  style: TextStyle(color: Colors.grey[600], fontSize: 12),
                ),
                const SizedBox(height: 4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      price,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: Colors.red,
                      ),
                    ),
                    InkWell(
                      onTap: () {
                        // Handle add to cart logic
                        // Example: addToCart({"name": name, "price": price, "size": size});
                      },
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: Colors.red,
                          borderRadius: BorderRadius.circular(5),
                        ),
                        child: const Icon(Icons.add, color: Colors.white, size: 20),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

void _launchMap(String address) async {
  final encodedAddress = Uri.encodeComponent(address);
  final url = 'https://www.google.com/maps/search/?api=1&query=$encodedAddress';
  if (await canLaunchUrl(Uri.parse(url))) {
    await launchUrl(Uri.parse(url));
  } else {
    throw 'Could not launch map for $address';
  }
}

Widget bannerlist(String imgpath) {
  return Padding(
    padding: const EdgeInsets.symmetric(horizontal: 8),
    child: Container(
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(8)),
      child: Image.asset(imgpath, fit: BoxFit.cover),
    ),
  );
}
