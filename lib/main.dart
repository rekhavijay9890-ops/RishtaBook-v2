import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Yahan apni Firebase keys zaroor daalein (Pehle ki tarah)
  await Firebase.initializeApp(
    options: const FirebaseOptions(
      apiKey:
          "AIzaSyBlScDXJDv6P6kcR6c5FUyWxT_LAyucduE", // Yeh project ki master key hai
      appId:
          "1:838898779560:android:14edeacd3f6af2b853099d", // Aapka naya Android ID
      messagingSenderId: "838898779560",
      projectId: "rishtabook-60663",
    ),
  );

  runApp(const MyApp());
}

// ==========================================
// AUTO-LOGIN
// ==========================================
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'RishtaBook',
      theme: ThemeData(primaryColor: const Color(0xFF0F766E)),
      home: StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(
                body: Center(
                    child:
                        CircularProgressIndicator(color: Color(0xFF0F766E))));
          }
          if (snapshot.hasData) {
            return const DashboardScreen();
          }
          return const LoginScreen();
        },
      ),
    );
  }
}

// ==========================================
// 1. REGISTRATION & LOGIN SCREEN (DOB Calendar & Auto Avatar)
// ==========================================
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool _isLoginMode = true;
  bool _isLoading = false;
  bool _isDisclaimerAccepted = false;

  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _ageController =
      TextEditingController(); // DOB (Calendar se bharega)
  final TextEditingController _mobileController =
      TextEditingController(); // Admin Only Mobile
  final TextEditingController _genderController = TextEditingController();
  final TextEditingController _villageController = TextEditingController();
  final TextEditingController _districtController = TextEditingController();
  final TextEditingController _stateController = TextEditingController();
  final TextEditingController _religionController = TextEditingController();
  final TextEditingController _categoryController = TextEditingController();
  final TextEditingController _occupationController = TextEditingController();
  final TextEditingController _familyDetailsController =
      TextEditingController();
  final TextEditingController _requirementsController = TextEditingController();

  Future<void> _submitForm() async {
    setState(() {
      _isLoading = true;
    });

    String email = _emailController.text.trim();
    String password = _passwordController.text.trim();

    bool isEmailValid = RegExp(
            r"^[a-zA-Z0-9.a-zA-Z0-9.!#$%&'*+-/=?^_`{|}~]+@[a-zA-Z0-9]+\.[a-zA-Z]+")
        .hasMatch(email);

    if (email.isEmpty || password.isEmpty) {
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text("Kripya Email aur Password bharein."),
            backgroundColor: Colors.red));
      setState(() {
        _isLoading = false;
      });
      return;
    }

    if (!isEmailValid) {
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text("Kripya ek sahi Gmail ID daalein."),
            backgroundColor: Colors.red));
      setState(() {
        _isLoading = false;
      });
      return;
    }

    if (!_isLoginMode) {
      if (_nameController.text.trim().isEmpty ||
          _ageController.text.trim().isEmpty ||
          _mobileController.text.trim().isEmpty ||
          _genderController.text.trim().isEmpty ||
          _religionController.text.trim().isEmpty ||
          _categoryController.text.trim().isEmpty ||
          _villageController.text.trim().isEmpty ||
          _districtController.text.trim().isEmpty ||
          _stateController.text.trim().isEmpty ||
          _occupationController.text.trim().isEmpty ||
          _familyDetailsController.text.trim().isEmpty ||
          _requirementsController.text.trim().isEmpty) {
        if (mounted)
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
              content: Text(
                  "Kripya sabhi details bharein, koi bhi field khali na chhodein."),
              backgroundColor: Colors.red));
        setState(() {
          _isLoading = false;
        });
        return;
      }

      if (_mobileController.text.trim().length < 10) {
        if (mounted)
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
              content: Text("Kripya ek sahi 10-digit Mobile Number daalein."),
              backgroundColor: Colors.red));
        setState(() {
          _isLoading = false;
        });
        return;
      }

      if (!_isDisclaimerAccepted) {
        if (mounted)
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
              content: Text("Kripya Disclaimer par tick karke agree karein."),
              backgroundColor: Colors.red));
        setState(() {
          _isLoading = false;
        });
        return;
      }
    }

    try {
      if (_isLoginMode) {
        await FirebaseAuth.instance
            .signInWithEmailAndPassword(email: email, password: password);
      } else {
        UserCredential userCredential = await FirebaseAuth.instance
            .createUserWithEmailAndPassword(email: email, password: password);

        // 🌟 LOGIC: Gender ke hisaab se default avatar set karna
        String selectedGender = _genderController.text.trim();
        String defaultAvatar = (selectedGender.toLowerCase() == 'female')
            ? 'assets/girl.png'
            : 'assets/boy.png';

        await FirebaseFirestore.instance
            .collection('users')
            .doc(userCredential.user!.uid)
            .set({
          'uid': userCredential.user!.uid,
          'fullName': _nameController.text.trim(),
          'age': _ageController.text.trim(), // Yahan ab DOB aayegi
          'mobile': _mobileController.text.trim(),
          'gender': selectedGender,
          'avatar': defaultAvatar, // 🌟 Avatar Save ho raha hai
          'religion': _religionController.text.trim(),
          'category': _categoryController.text.trim(),
          'village': _villageController.text.trim(),
          'district': _districtController.text.trim(),
          'state': _stateController.text.trim(),
          'occupation': _occupationController.text.trim(),
          'familyDetails': _familyDetailsController.text.trim(),
          'requirements': _requirementsController.text.trim(),
          'email': email,
          'createdAt': DateTime.now(),
        });
      }
      if (mounted)
        Navigator.pushReplacement(context,
            MaterialPageRoute(builder: (context) => const DashboardScreen()));
    } on FirebaseAuthException catch (e) {
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content:
                Text(e.message ?? "Error: Account banane mein dikkat aayi."),
            backgroundColor: Colors.red));
    } finally {
      if (mounted)
        setState(() {
          _isLoading = false;
        });
    }
  }

  Future<void> _signInWithGoogle() async {
    setState(() {
      _isLoading = true;
    });
    try {
      GoogleAuthProvider googleProvider = GoogleAuthProvider();
      UserCredential userCredential =
          await FirebaseAuth.instance.signInWithPopup(googleProvider);

      if (userCredential.additionalUserInfo?.isNewUser ?? false) {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(userCredential.user!.uid)
            .set({
          'uid': userCredential.user!.uid,
          'fullName': userCredential.user!.displayName ?? 'Naya User',
          'email': userCredential.user!.email,
          'avatar': 'assets/boy.png', // Google sign-in default
          'createdAt': DateTime.now(),
        });
      }
      if (mounted)
        Navigator.pushReplacement(context,
            MaterialPageRoute(builder: (context) => const DashboardScreen()));
    } catch (e) {
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text("Error: ${e.toString()}"),
            backgroundColor: Colors.red));
    } finally {
      if (mounted)
        setState(() {
          _isLoading = false;
        });
    }
  }

  void _showForgotPasswordDialog() {
    final TextEditingController resetEmailController =
        TextEditingController(text: _emailController.text);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        title: const Text("Reset Password",
            style: TextStyle(
                color: Color(0xFF0F766E), fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
                "Apna registered email daalein, hum aapko password reset karne ka link bhejenge.",
                style: TextStyle(color: Colors.grey, fontSize: 13)),
            const SizedBox(height: 15),
            TextField(
              controller: resetEmailController,
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.email, color: Color(0xFF0F766E)),
                hintText: "Gmail ID",
                border:
                    OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: Color(0xFF0F766E))),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child:
                  const Text("Cancel", style: TextStyle(color: Colors.grey))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0F766E),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8))),
            onPressed: () async {
              if (resetEmailController.text.isNotEmpty) {
                try {
                  await FirebaseAuth.instance.sendPasswordResetEmail(
                      email: resetEmailController.text.trim());
                  if (context.mounted) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                        content: Text(
                            "Password reset link aapke email par bhej diya gaya hai!"),
                        backgroundColor: Colors.green));
                  }
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                        content: Text("Error: Email nahi mila ya galat hai."),
                        backgroundColor: Colors.red));
                  }
                }
              }
            },
            child:
                const Text("Send Link", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(30.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                    color: const Color(0xFFE0F2FE),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                          color: Colors.black.withOpacity(0.1), blurRadius: 10)
                    ]),
                child: Image.asset('assets/icon.png',
                    width: 100,
                    height: 100,
                    errorBuilder: (context, error, stackTrace) => const Icon(
                        Icons.favorite,
                        color: Colors.pink,
                        size: 50)),
              ),
              const SizedBox(height: 30),
              Text(_isLoginMode ? "Welcome Back!" : "Create Account",
                  style: const TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF0F766E))),
              const SizedBox(height: 40),
              if (!_isLoginMode) ...[
                _buildInputField(Icons.person, "Full Name", _nameController),
                const SizedBox(height: 15),
                Row(children: [
                  Expanded(
                      child:
                          _buildDobField()), // 🌟 NAYA: DOB Calendar Wala Field
                  const SizedBox(width: 15),
                  Expanded(child: _buildGenderDropdown())
                ]),
                const SizedBox(height: 15),
                _buildInputField(Icons.phone, "Mobile Number (For Admin Only)",
                    _mobileController,
                    isNumber: true),
                const SizedBox(height: 15),
                Row(children: [
                  Expanded(child: _buildReligionDropdown()),
                  const SizedBox(width: 15),
                  Expanded(child: _buildCategoryDropdown())
                ]),
                const SizedBox(height: 15),
                Row(children: [
                  Expanded(
                      child: _buildInputField(Icons.home, "Gaon / Town / City",
                          _villageController)),
                  const SizedBox(width: 15),
                  Expanded(
                      child: _buildInputField(Icons.location_city,
                          "Jila (District)", _districtController))
                ]),
                const SizedBox(height: 15),
                _buildInputField(
                    Icons.map, "Pradesh (State)", _stateController),
                const SizedBox(height: 15),
                _buildOccupationDropdown(),
                const SizedBox(height: 15),
                _buildInputField(
                    Icons.family_restroom,
                    "Family Details (Occupation, Income, etc.)",
                    _familyDetailsController,
                    maxLines: 2),
                const SizedBox(height: 15),
                _buildInputField(
                    Icons.list_alt,
                    "Any other requirement / condition",
                    _requirementsController,
                    maxLines: 2),
                const SizedBox(height: 15),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      height: 24,
                      width: 24,
                      child: Checkbox(
                        value: _isDisclaimerAccepted,
                        onChanged: (bool? value) {
                          setState(() {
                            _isDisclaimerAccepted = value ?? false;
                          });
                        },
                        activeColor: const Color(0xFF0F766E),
                      ),
                    ),
                    const SizedBox(width: 10),
                    const Expanded(
                      child: Text(
                        "Disclaimer: Hamara kaam bas do families ko connect karana hai, Ladka/Ladki aur pariwar ke baare main janch aur padtal karna aapki jimmedaari hai. Hamari app ke through koi bhi galat ya fraud activity ke liye ham zimmedar nahi hain.",
                        style: TextStyle(fontSize: 13, color: Colors.black87),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
              ],
              _buildInputField(Icons.email, "Gmail ID", _emailController),
              const SizedBox(height: 15),
              _buildInputField(Icons.lock, "Password", _passwordController,
                  isPassword: true),
              if (_isLoginMode)
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: _showForgotPasswordDialog,
                    child: const Text("Forgot Password?",
                        style: TextStyle(
                            color: Color(0xFF0F766E),
                            fontWeight: FontWeight.bold)),
                  ),
                ),
              const SizedBox(height: 15),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0F766E),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10))),
                  onPressed: _isLoading ? null : _submitForm,
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : Text(_isLoginMode ? "Secure Login" : "Sign Up",
                          style: const TextStyle(
                              fontSize: 18, color: Colors.white)),
                ),
              ),
              const SizedBox(height: 20),
              const Row(children: [
                Expanded(child: Divider()),
                Padding(
                    padding: EdgeInsets.symmetric(horizontal: 10),
                    child: Text("OR",
                        style: TextStyle(
                            color: Colors.grey, fontWeight: FontWeight.bold))),
                Expanded(child: Divider())
              ]),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: OutlinedButton.icon(
                  icon: const Icon(Icons.account_circle,
                      color: Colors.red, size: 28),
                  label: const Text("Continue with Google",
                      style: TextStyle(
                          fontSize: 16,
                          color: Colors.black87,
                          fontWeight: FontWeight.bold)),
                  style: OutlinedButton.styleFrom(
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                      side: BorderSide(color: Colors.grey.shade300)),
                  onPressed: _isLoading ? null : _signInWithGoogle,
                ),
              ),
              const SizedBox(height: 30),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                      _isLoginMode
                          ? "Don't have an account? "
                          : "Already have an account? ",
                      style: const TextStyle(color: Colors.grey)),
                  GestureDetector(
                    onTap: () {
                      setState(() {
                        _isLoginMode = !_isLoginMode;
                        _emailController.clear();
                        _passwordController.clear();
                      });
                    },
                    child: Text(_isLoginMode ? "Sign Up" : "Login",
                        style: const TextStyle(
                            color: Color(0xFF0F766E),
                            fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // 🌟 NAYA LOGIC: Date of Birth Calendar Field
  Widget _buildDobField() {
    return TextField(
      controller: _ageController,
      readOnly: true, // Keyboard disable, Calendar enable
      onTap: () async {
        DateTime? picked = await showDatePicker(
          context: context,
          initialDate: DateTime(2000, 1, 1),
          firstDate: DateTime(1950),
          lastDate: DateTime.now()
              .subtract(const Duration(days: 6570)), // Minimum 18 saal ki umar
          builder: (context, child) {
            return Theme(
              data: Theme.of(context).copyWith(
                colorScheme: const ColorScheme.light(
                  primary: Color(0xFF0F766E),
                  onPrimary: Colors.white,
                  onSurface: Colors.black,
                ),
              ),
              child: child!,
            );
          },
        );
        if (picked != null) {
          setState(() {
            _ageController.text =
                "${picked.day.toString().padLeft(2, '0')}/${picked.month.toString().padLeft(2, '0')}/${picked.year}";
          });
        }
      },
      decoration: InputDecoration(
        prefixIcon: const Icon(Icons.calendar_today, color: Color(0xFF0F766E)),
        hintText: "Date of Birth",
        contentPadding:
            const EdgeInsets.symmetric(vertical: 15, horizontal: 15),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(color: Colors.grey.shade400)),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: Color(0xFF0F766E), width: 2)),
      ),
    );
  }

  Widget _buildInputField(
      IconData icon, String hint, TextEditingController controller,
      {bool isPassword = false, int maxLines = 1, bool isNumber = false}) {
    return TextField(
      controller: controller,
      obscureText: isPassword,
      maxLines: isPassword ? 1 : maxLines,
      keyboardType: isNumber ? TextInputType.phone : TextInputType.text,
      decoration: InputDecoration(
        prefixIcon: Padding(
          padding:
              EdgeInsets.only(bottom: maxLines > 1 ? (maxLines * 10.0) : 0),
          child: Icon(icon, color: const Color(0xFF0F766E)),
        ),
        hintText: hint,
        contentPadding:
            const EdgeInsets.symmetric(vertical: 15, horizontal: 15),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(color: Colors.grey.shade400)),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: Color(0xFF0F766E), width: 2)),
      ),
    );
  }

  Widget _buildGenderDropdown() {
    return DropdownButtonFormField<String>(
      isExpanded: true,
      decoration: InputDecoration(
        prefixIcon: const Icon(Icons.people, color: Color(0xFF0F766E)),
        hintText: "Gender",
        contentPadding: const EdgeInsets.symmetric(vertical: 15),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(color: Colors.grey.shade400)),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: Color(0xFF0F766E), width: 2)),
      ),
      items: ["Male", "Female", "Other"]
          .map((String value) =>
              DropdownMenuItem<String>(value: value, child: Text(value)))
          .toList(),
      onChanged: (newValue) {
        if (newValue != null) {
          _genderController.text = newValue;
        }
      },
    );
  }

  Widget _buildReligionDropdown() {
    return DropdownButtonFormField<String>(
      isExpanded: true,
      decoration: InputDecoration(
        prefixIcon: const Icon(Icons.menu_book, color: Color(0xFF0F766E)),
        hintText: "Religion",
        contentPadding: const EdgeInsets.symmetric(vertical: 15),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(color: Colors.grey.shade400)),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: Color(0xFF0F766E), width: 2)),
      ),
      items: ["Hindu", "Muslim", "Sikh", "Ishai"]
          .map((String value) =>
              DropdownMenuItem<String>(value: value, child: Text(value)))
          .toList(),
      onChanged: (newValue) {
        if (newValue != null) {
          _religionController.text = newValue;
        }
      },
    );
  }

  Widget _buildCategoryDropdown() {
    return DropdownButtonFormField<String>(
      isExpanded: true,
      decoration: InputDecoration(
        prefixIcon: const Icon(Icons.groups, color: Color(0xFF0F766E)),
        hintText: "Category",
        contentPadding: const EdgeInsets.symmetric(vertical: 15),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(color: Colors.grey.shade400)),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: Color(0xFF0F766E), width: 2)),
      ),
      items: ["General", "OBC", "SC", "ST", "Other"]
          .map((String value) =>
              DropdownMenuItem<String>(value: value, child: Text(value)))
          .toList(),
      onChanged: (newValue) {
        if (newValue != null) {
          _categoryController.text = newValue;
        }
      },
    );
  }

  Widget _buildOccupationDropdown() {
    return DropdownButtonFormField<String>(
      isExpanded: true,
      decoration: InputDecoration(
        prefixIcon: const Icon(Icons.work, color: Color(0xFF0F766E)),
        hintText: "Occupation",
        contentPadding: const EdgeInsets.symmetric(vertical: 15),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(color: Colors.grey.shade400)),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: Color(0xFF0F766E), width: 2)),
      ),
      items: ["Job", "Business", "Farming", "Other"]
          .map((String value) =>
              DropdownMenuItem<String>(value: value, child: Text(value)))
          .toList(),
      onChanged: (newValue) {
        if (newValue != null) {
          _occupationController.text = newValue;
        }
      },
    );
  }
}

// ==========================================
// 2. DASHBOARD SCREEN (Real Notifications Ke Sath)
// ==========================================
class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _selectedIndex = 0;
  final List<Widget> _pages = [
    const MatchesListTab(),
    const SavedMatchesTab(),
    const AdminChatTab(),
    const MyProfileTab(),
    const AboutUsTab()
  ];

  void _showNotifications() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        title: const Text("Recent Activities",
            style: TextStyle(
                color: Color(0xFF0F766E), fontWeight: FontWeight.bold)),
        content: SizedBox(
          width: double.maxFinite,
          height: 250,
          child: StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('users')
                .orderBy('createdAt', descending: true)
                .limit(5)
                .snapshots(),
            builder: (context, snapshot) {
              if (!snapshot.hasData)
                return const Center(child: CircularProgressIndicator());
              if (snapshot.data!.docs.isEmpty)
                return const Center(child: Text("Koi nayi activity nahi hai."));
              return ListView(
                children: snapshot.data!.docs.map((doc) {
                  var data = doc.data() as Map<String, dynamic>;
                  String name = data['fullName'] ?? 'Naya User';
                  String district = data['district'] ?? 'ek naye shahar';
                  return ListTile(
                    leading: const Icon(Icons.person_add, color: Colors.blue),
                    title: Text("$name ne app join kiya!"),
                    subtitle: Text("$district se hain."),
                  );
                }).toList(),
              );
            },
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Close",
                  style: TextStyle(color: Color(0xFF0F766E), fontSize: 16))),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        title: const Text("RishtaBook",
            style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFF0F766E),
        foregroundColor: Colors.white,
        elevation: 0,
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
              icon: const Icon(Icons.notifications_active),
              onPressed: _showNotifications)
        ],
      ),
      body: _pages[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: _selectedIndex,
        onTap: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        selectedItemColor: const Color(0xFF0F766E),
        unselectedItemColor: Colors.grey,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: "Home"),
          BottomNavigationBarItem(icon: Icon(Icons.favorite), label: "Matches"),
          BottomNavigationBarItem(icon: Icon(Icons.chat), label: "Chats"),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: "Profile"),
          BottomNavigationBarItem(
              icon: Icon(Icons.info_outline), label: "About Us"),
        ],
      ),
    );
  }
}

// ==========================================
// 3. HOME TAB (Real Profiles & Dynamic Gender Icons)
// ==========================================
class MatchesListTab extends StatelessWidget {
  const MatchesListTab({super.key});

  Future<void> _saveMatch(BuildContext context, String matchId,
      Map<String, dynamic> matchData) async {
    final User? user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('savedMatches')
          .doc(matchId)
          .set({
        ...matchData,
        'savedAt': DateTime.now(),
      });
      if (context.mounted)
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(
                "${matchData['fullName']} Saved Matches mein add ho gaye! ❤️"),
            backgroundColor: Colors.green));
    } catch (e) {
      if (context.mounted)
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text("Save karne mein error aayi."),
            backgroundColor: Colors.red));
    }
  }

  @override
  Widget build(BuildContext context) {
    final String currentUserId = FirebaseAuth.instance.currentUser?.uid ?? "";

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('users').snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
              child: CircularProgressIndicator(color: Color(0xFF0F766E)));
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(
              child: Text("Abhi tak koi naya profile nahi hai."));
        }

        // Khud ka profile hide karne ka logic
        var allProfiles = snapshot.data!.docs
            .where((doc) => doc.id != currentUserId)
            .toList();

        if (allProfiles.isEmpty) {
          return const Center(
              child: Text("Abhi aapke alawa koi aur user nahi hai.",
                  style: TextStyle(color: Colors.grey)));
        }

        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            const Text("Recommended Matches",
                style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF0F766E))),
            const SizedBox(height: 15),
            ...allProfiles.map((doc) {
              var data = doc.data() as Map<String, dynamic>;
              String name = data['fullName'] ?? "Naam nahi likha";
              String age = data['age'] ?? "--";
              String religion = data['religion'] ?? "--";
              String district = data['district'] ?? "";
              String state = data['state'] ?? "";
              String gender = data['gender'] ?? "";

              // Asli Gender Icon logic
              IconData avatarIcon = Icons.person;
              Color avatarColor = Colors.grey;
              if (gender.toLowerCase() == 'female') {
                avatarIcon = Icons.face_3;
                avatarColor = Colors.pink;
              } else if (gender.toLowerCase() == 'male') {
                avatarIcon = Icons.face;
                avatarColor = Colors.blue;
              }

              return Card(
                margin: const EdgeInsets.only(bottom: 15),
                elevation: 2,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15)),
                child: Padding(
                  padding: const EdgeInsets.all(15.0),
                  child: Row(
                    children: [
                      CircleAvatar(
                          radius: 35,
                          backgroundColor: avatarColor.withOpacity(0.1),
                          child:
                              Icon(avatarIcon, size: 40, color: avatarColor)),
                      const SizedBox(width: 15),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(name,
                                style: const TextStyle(
                                    fontSize: 18, fontWeight: FontWeight.bold)),
                            const SizedBox(height: 5),
                            Text("$age Yrs • $religion",
                                style: TextStyle(color: Colors.grey.shade700)),
                            const SizedBox(height: 5),
                            Row(children: [
                              const Icon(Icons.location_on,
                                  size: 16, color: Colors.grey),
                              Text("$district, $state",
                                  style: const TextStyle(color: Colors.grey))
                            ]),
                          ],
                        ),
                      ),
                      IconButton(
                          icon: const Icon(Icons.favorite_border,
                              color: Colors.pink, size: 30),
                          onPressed: () => _saveMatch(context, doc.id, data))
                    ],
                  ),
                ),
              );
            }),
          ],
        );
      },
    );
  }
}

// ==========================================
// 3. SAVED MATCHES TAB (Category aur Requirement ke sath)
// ==========================================
class SavedMatchesTab extends StatelessWidget {
  const SavedMatchesTab({super.key});

  @override
  Widget build(BuildContext context) {
    final User? user = FirebaseAuth.instance.currentUser;
    if (user == null) return const Center(child: Text("Kripya login karein"));

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('savedMatches')
          .orderBy('savedAt', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting)
          return const Center(
              child: CircularProgressIndicator(color: Color(0xFF0F766E)));
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.favorite_border,
                    size: 60, color: Colors.grey.shade400),
                const SizedBox(height: 15),
                const Text("Abhi tak koi match save nahi kiya hai.",
                    style: TextStyle(fontSize: 16, color: Colors.grey))
              ],
            ),
          );
        }

        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            const Text("My Saved Matches (Biodata)",
                style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF0F766E))),
            const SizedBox(height: 15),
            ...snapshot.data!.docs.map((doc) {
              var data = doc.data() as Map<String, dynamic>;
              String name = data['fullName'] ?? "--";
              String dob = data['age'] ?? "--";
              String gender = data['gender'] ?? "--";
              String religion = data['religion'] ?? "--";
              String category = data['category'] ?? "N/A"; // NAYA: Category
              String occupation = data['occupation'] ?? "N/A";
              String requirement =
                  data['requirements'] ?? "N/A"; // NAYA: Requirement
              String village = data['village'] ?? "--";
              String district = data['district'] ?? "--";
              String state = data['state'] ?? "--";

              return Card(
                margin: const EdgeInsets.only(bottom: 15),
                elevation: 3,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15)),
                child: Padding(
                  padding: const EdgeInsets.all(15.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(name,
                              style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF0F766E))),
                          IconButton(
                            icon: const Icon(Icons.delete_outline,
                                color: Colors.red),
                            onPressed: () {
                              FirebaseFirestore.instance
                                  .collection('users')
                                  .doc(user.uid)
                                  .collection('savedMatches')
                                  .doc(doc.id)
                                  .delete();
                            },
                          )
                        ],
                      ),
                      const Divider(),

                      _buildBiodataRow(Icons.person, "Basic Info",
                          "DOB: $dob • $gender • $religion"),
                      const SizedBox(height: 8),

                      // NAYA: Category aur Occupation
                      _buildBiodataRow(Icons.groups, "Category", category),
                      const SizedBox(height: 8),

                      _buildBiodataRow(Icons.work, "Occupation", occupation),
                      const SizedBox(height: 8),

                      _buildBiodataRow(Icons.home, "Address",
                          "$village, Dist: $district, $state"),
                      const SizedBox(height: 8),

                      // NAYA: Special Requirement
                      _buildBiodataRow(
                          Icons.list_alt, "Requirement", requirement),
                      const SizedBox(height: 8),

                      const Divider(),

                      _buildBiodataRow(
                          Icons.phone, "Mobile No.", "🔒 Hidden for Privacy",
                          isHidden: true),
                      const SizedBox(height: 8),
                      _buildBiodataRow(
                          Icons.camera_alt, "Photo", "🔒 Hidden for Privacy",
                          isHidden: true),
                      const SizedBox(height: 15),

                      // WhatsApp Button
                      SizedBox(
                        width: double.infinity,
                        height: 45,
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green.shade600,
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10))),
                          icon: const Icon(Icons.chat, color: Colors.white),
                          label: const Text("Connect via WhatsApp",
                              style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold)),
                          onPressed: () async {
                            const String adminNumber =
                                "919415867748"; // Aap yahan apna admin number daal sakti hain
                            String message =
                                "Hello Admin, main RishtaBook app se hoon. Mujhe $name ki profile ke baare mein jaankari chahiye.";
                            final Uri whatsappUrl = Uri.parse(
                                "https://wa.me/$adminNumber?text=${Uri.encodeComponent(message)}");
                            try {
                              await launchUrl(whatsappUrl);
                            } catch (e) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                      content: Text(
                                          "Error: WhatsApp nahi khul paya.")));
                            }
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
          ],
        );
      },
    );
  }

  Widget _buildBiodataRow(IconData icon, String title, String value,
      {bool isHidden = false}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon,
            size: 20,
            color: isHidden ? Colors.red.shade400 : const Color(0xFF0F766E)),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title,
                  style: const TextStyle(fontSize: 12, color: Colors.grey)),
              Text(value,
                  style: TextStyle(
                      fontSize: 15,
                      fontWeight: isHidden ? FontWeight.bold : FontWeight.w500,
                      color: isHidden ? Colors.red.shade400 : Colors.black87)),
            ],
          ),
        ),
      ],
    );
  }
}

// ==========================================
// 5. ADMIN CHAT TAB
// ==========================================
class AdminChatTab extends StatelessWidget {
  const AdminChatTab({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
                padding: const EdgeInsets.all(25),
                decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.1),
                    shape: BoxShape.circle),
                child:
                    const Icon(Icons.security, size: 80, color: Colors.green)),
            const SizedBox(height: 25),
            const Text("100% Safe & Secure",
                style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF0F766E))),
            const SizedBox(height: 15),
            const Text(
                "Aapki privacy hamari pehli priority hai.\nKisi bhi profile ki detail lene ya connect karne ke liye kripya hamare Admin se WhatsApp par sampark karein.",
                textAlign: TextAlign.center,
                style:
                    TextStyle(fontSize: 16, color: Colors.grey, height: 1.5)),
            const SizedBox(height: 40),
            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green.shade600,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10))),
                icon: const Icon(Icons.chat, color: Colors.white, size: 28),
                label: const Text("Chat with Admin on WhatsApp",
                    style: TextStyle(
                        fontSize: 18,
                        color: Colors.white,
                        fontWeight: FontWeight.bold)),
                onPressed: () async {
                  const String adminNumber = "919415867748";
                  const String message =
                      "Hello Admin, RishtaBook se related questions hain. Can we connect?";
                  final Uri whatsappUrl = Uri.parse(
                      "https://wa.me/$adminNumber?text=${Uri.encodeComponent(message)}");
                  try {
                    await launchUrl(whatsappUrl);
                  } catch (e) {
                    if (context.mounted)
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                          content: Text("Error: WhatsApp nahi khul paya."),
                          backgroundColor: Colors.red));
                  }
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ==========================================
// 4. PROFILE TAB (Naye Fields Ke Sath)
// ==========================================
class MyProfileTab extends StatelessWidget {
  const MyProfileTab({super.key});

  @override
  Widget build(BuildContext context) {
    final User? user = FirebaseAuth.instance.currentUser;
    if (user == null) return const Center(child: Text("Kripya login karein"));

    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
              child: CircularProgressIndicator(color: Color(0xFF0F766E)));
        }

        // Agar user ka data delete ho gaya ho (Blank screen issue fix)
        if (!snapshot.hasData || !snapshot.data!.exists) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 60, color: Colors.red),
                const SizedBox(height: 15),
                const Text("Profile data nahi mila ya delete ho gaya hai.",
                    style: TextStyle(fontSize: 16)),
                const SizedBox(height: 20),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                  onPressed: () async {
                    await FirebaseAuth.instance.signOut();
                    if (context.mounted)
                      Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                              builder: (context) => const LoginScreen()));
                  },
                  child: const Text("Logout",
                      style: TextStyle(color: Colors.white)),
                )
              ],
            ),
          );
        }

        var data = snapshot.data!.data() as Map<String, dynamic>;

        return ListView(
          padding: const EdgeInsets.all(20),
          children: [
            const Center(
              child: CircleAvatar(
                radius: 50,
                backgroundColor: Color(0xFF0F766E),
                child: Icon(Icons.person, size: 60, color: Colors.white),
              ),
            ),
            const SizedBox(height: 15),
            Text(data['fullName'] ?? "N/A",
                textAlign: TextAlign.center,
                style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF0F766E))),
            Text(data['email'] ?? "N/A",
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.grey, fontSize: 14)),
            const SizedBox(height: 25),

            // Saari Details Yahan Dikhengi
            _buildProfileItem(
                Icons.calendar_today, "Date of Birth", data['age'] ?? "N/A"),
            _buildProfileItem(Icons.people, "Gender", data['gender'] ?? "N/A"),
            _buildProfileItem(
                Icons.menu_book, "Religion", data['religion'] ?? "N/A"),
            _buildProfileItem(
                Icons.groups, "Category", data['category'] ?? "N/A"),
            _buildProfileItem(
                Icons.work, "Occupation", data['occupation'] ?? "N/A"),
            _buildProfileItem(Icons.home, "Address",
                "${data['village'] ?? ''}, Dist: ${data['district'] ?? ''}, ${data['state'] ?? ''}"),
            _buildProfileItem(Icons.family_restroom, "Family Details",
                data['familyDetails'] ?? "N/A"),
            _buildProfileItem(
                Icons.list_alt, "Requirement", data['requirements'] ?? "N/A"),

            const SizedBox(height: 30),

            // Logout Button
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red.shade600,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10))),
                icon: const Icon(Icons.logout, color: Colors.white),
                label: const Text("Logout Account",
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold)),
                onPressed: () async {
                  await FirebaseAuth.instance.signOut();
                  if (context.mounted)
                    Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                            builder: (context) => const LoginScreen()));
                },
              ),
            ),
            const SizedBox(height: 20),
          ],
        );
      },
    );
  }

  // Profile fields ko sundar dikhane ka design
  Widget _buildProfileItem(IconData icon, String title, String value) {
    return Card(
      elevation: 1,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: Padding(
        padding: const EdgeInsets.all(15.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: const Color(0xFF0F766E), size: 24),
            const SizedBox(width: 15),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: const TextStyle(fontSize: 12, color: Colors.grey)),
                  const SizedBox(height: 4),
                  Text(value,
                      style: const TextStyle(
                          fontSize: 15,
                          color: Colors.black87,
                          fontWeight: FontWeight.w500)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ==========================================
// 7. ABOUT US TAB
// ==========================================
class AboutUsTab extends StatelessWidget {
  const AboutUsTab({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(30.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
                padding: const EdgeInsets.all(20),
                decoration: const BoxDecoration(
                    color: Color(0xFFE0F2FE), shape: BoxShape.circle),
                child:
                    const Icon(Icons.favorite, size: 60, color: Colors.pink)),
            const SizedBox(height: 20),
            const Text("RishtaBook",
                style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF0F766E))),
            const SizedBox(height: 10),
            const Text("Version 1.0.0", style: TextStyle(color: Colors.grey)),
            const SizedBox(height: 30),
            const Text(
                "RishtaBook is India's most trusted premium matchmaking platform. Humara maksad hai do dilon ko ek surakshit aur modern tarike se milana.",
                textAlign: TextAlign.center,
                style: TextStyle(
                    fontSize: 16, height: 1.5, color: Colors.black87)),
            const SizedBox(height: 40),
            const Text("Made with ❤️ in India",
                style:
                    TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
          ],
        ),
      ),
    );
  }
}
