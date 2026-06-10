import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'payment_confirmation_page.dart';

const primaryBlue = Color(0xFF7DA7D9);
const softPink = Color(0xFFF7A6B8);
const deepBrown = Color(0xFF5D4037);
const bg = Color.fromARGB(255, 205, 223, 232);

class ConvertPage extends StatefulWidget {
  const ConvertPage({super.key});

  @override
  State<ConvertPage> createState() => _ConvertPageState();
}

class _ConvertPageState extends State<ConvertPage> {
  final TextEditingController _ctrl = TextEditingController();
  double res = 0;
  String from = "USD";
  String to = "IDR";
  bool loading = false;
  String selectedPlan = "";

  // Tipe Plan dan Style-nya
  final List<Map<String, dynamic>> planTypes = [
    {
      "name": "Individual",
      "color": const Color.fromARGB(255, 104, 84, 72),
      "icon": Icons.person
    },
    {"name": "Duo", "color": softPink, "icon": Icons.people_alt},
    {
      "name": "Family",
      "color": const Color(0xFFB39DDB),
      "icon": Icons.family_restroom
    },
    {"name": "Student", "color": const Color(0xFFFFB74D), "icon": Icons.school},
  ];

  // Harga Base Berdasarkan Mata Uang (Dinamis sesuai yang dipilih user)
  final Map<String, List<double>> planPrices = {
    "USD": [10.99, 14.99, 16.99, 5.99],
    "IDR": [54900, 71490, 86900, 27500],
    "MYR": [14.90, 19.80, 23.80, 7.50],
    "JPY": [980, 1280, 1480, 480],
    "KRW": [10900, 16350, 17900, 5900],
    "EUR": [9.99, 13.99, 15.99, 4.99],
  };

  String _getCurrencySymbol(String currency) {
    switch (currency) {
      case 'USD':
        return '\$';
      case 'IDR':
        return 'Rp ';
      case 'MYR':
        return 'RM ';
      case 'JPY':
        return '¥';
      case 'KRW':
        return '₩';
      case 'EUR':
        return '€';
      default:
        return '$currency ';
    }
  }

  Future<void> _convert({double? manualAmount}) async {
    String input = manualAmount != null ? manualAmount.toString() : _ctrl.text;
    if (input.trim().isEmpty) return;

    // Tutup keyboard
    FocusScope.of(context).unfocus();
    setState(() => loading = true);

    try {
      String fromLower = from.toLowerCase();
      String toLower = to.toLowerCase();
      final url = Uri.parse(
          "https://latest.currency-api.pages.dev/v1/currencies/$fromLower.json");

      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final rate = data[fromLower][toLower];
        final amount = double.tryParse(input) ?? 0;

        setState(() {
          res = (amount * rate).toDouble();
          if (manualAmount != null) _ctrl.text = manualAmount.toString();
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Gagal mengambil data kurs ❌")),
        );
      }
    } finally {
      setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        title: const Text("Premium Estimator",
            style: TextStyle(fontWeight: FontWeight.w600, color: Colors.white)),
        backgroundColor: primaryBlue,
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Pilih Paket Premium",
                style: TextStyle(
                    color: deepBrown,
                    fontSize: 18,
                    fontWeight: FontWeight.w800)),
            const SizedBox(height: 6),
            const Text(
                "Pilih mata uang asal terlebih dahulu, harga paket akan otomatis menyesuaikan wilayahmu.",
                style: TextStyle(
                    color: Color.fromARGB(255, 56, 44, 36),
                    fontSize: 13,
                    height: 1.4)),
            const SizedBox(height: 20),
            const SizedBox(height: 20),
            _buildCurrencyRow(),
            const SizedBox(height: 20),
            SizedBox(
              height: 175,
              child: ListView.builder(
                physics: const BouncingScrollPhysics(),
                scrollDirection: Axis.horizontal,
                itemCount: planTypes.length,
                itemBuilder: (context, index) {
                  return _buildPremiumPlanCard(index);
                },
              ),
            ),
            const SizedBox(height: 30),
            const Text("Atau Hitung Manual",
                style: TextStyle(
                    color: deepBrown,
                    fontSize: 16,
                    fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            _buildCustomInput(),
            const SizedBox(height: 30),
            Center(
              child: ElevatedButton.icon(
                onPressed: loading ? null : () => _convert(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: softPink,
                  foregroundColor: const Color.fromARGB(255, 255, 255, 255),
                  minimumSize: const Size(double.infinity, 55),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  elevation: 0,
                ),
                icon: loading
                    ? const SizedBox.shrink()
                    : const Icon(Icons.calculate_rounded, size: 24),
                label: loading
                    ? const SizedBox(
                        height: 24,
                        width: 24,
                        child: CircularProgressIndicator(
                            color: Colors.white, strokeWidth: 2))
                    : const Text("Hitung Estimasi Harga",
                        style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            letterSpacing: 0.5)),
              ),
            ),
            const SizedBox(height: 35),
            _buildResultCard(),
            const SizedBox(height: 30),
            if (res > 0)
              SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: deepBrown,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => PaymentConfirmationPage(
                          planName: selectedPlan.isNotEmpty
                              ? "Paket $selectedPlan"
                              : "Paket Custom",
                          amount: res,
                          currency: to,
                        ),
                      ),
                    );
                  },
                  child: const Text("Lanjutkan Pembayaran",
                      style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white)),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildPremiumPlanCard(int index) {
    final plan = planTypes[index];
    final price = planPrices[from]![index];
    final isSelected = _ctrl.text == price.toString();

    return GestureDetector(
      onTap: () {
        setState(() {
          _ctrl.text = price.toString();
          selectedPlan = plan['name'];
        });
        _convert(manualAmount: price);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        width: 150,
        margin: const EdgeInsets.only(right: 15, bottom: 5, top: 5),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? softPink : Colors.transparent,
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: plan['color'].withOpacity(0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text("1 Bulan Gratis",
                  style: TextStyle(
                      color: plan['color'],
                      fontSize: 10,
                      fontWeight: FontWeight.w800)),
            ),
            const Spacer(),
            Icon(plan['icon'], color: plan['color'], size: 30),
            const SizedBox(height: 10),
            Text(plan['name'],
                style: const TextStyle(
                    color: deepBrown,
                    fontSize: 16,
                    fontWeight: FontWeight.bold)),
            const SizedBox(height: 2),
            Text("${_getCurrencySymbol(from)}$price/bln",
                style: const TextStyle(
                    color: Colors.black87,
                    fontSize: 15,
                    fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }

  Widget _buildCustomInput() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: TextField(
        controller: _ctrl,
        onChanged: (val) => setState(() => selectedPlan = ""),
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        style: const TextStyle(
            color: deepBrown, fontSize: 16, fontWeight: FontWeight.w600),
        decoration: const InputDecoration(
          hintText: "Masukkan nominal...",
          hintStyle: TextStyle(
              color: Colors.grey, fontSize: 14, fontWeight: FontWeight.normal),
          prefixIcon: Icon(Icons.edit_note_rounded, color: primaryBlue),
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(vertical: 15),
        ),
      ),
    );
  }

  Widget _buildCurrencyRow() {
    return Row(
      children: [
        _miniDropdown(from, "Dari", (v) {
          setState(() {
            from = v!;
            _ctrl.clear(); // Reset input ketika mengganti mata uang utama
            res = 0;
            selectedPlan = "";
          });
        }),
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 15),
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
              color: softPink.withOpacity(0.2), shape: BoxShape.circle),
          child: const Icon(Icons.swap_horiz_rounded, color: softPink),
        ),
        _miniDropdown(to, "Ke", (v) => setState(() => to = v!)),
      ],
    );
  }

  Widget _miniDropdown(
      String value, String label, Function(String?) onChanged) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: const TextStyle(
                  fontSize: 12,
                  color: Colors.grey,
                  fontWeight: FontWeight.bold)),
          const SizedBox(height: 5),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 15),
            decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(15),
                boxShadow: [
                  BoxShadow(
                      color: Colors.black.withOpacity(0.03),
                      blurRadius: 10,
                      offset: const Offset(0, 4))
                ]),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: value,
                isExpanded: true,
                dropdownColor: Colors.white,
                icon: const Icon(Icons.keyboard_arrow_down, color: primaryBlue),
                style: const TextStyle(
                    color: deepBrown,
                    fontWeight: FontWeight.w700,
                    fontSize: 16),
                items: ["USD", "IDR", "EUR", "MYR", "JPY", "KRW"]
                    .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                    .toList(),
                onChanged: onChanged,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResultCard() {
    int decimals = ['IDR', 'KRW', 'JPY'].contains(to) ? 0 : 2;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(25),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: primaryBlue.withOpacity(0.15),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            decoration: BoxDecoration(
                color: bg, borderRadius: BorderRadius.circular(20)),
            child: Text("TOTAL ESTIMASI ($to)",
                style: const TextStyle(
                    color: Colors.grey,
                    fontSize: 12,
                    letterSpacing: 1,
                    fontWeight: FontWeight.bold)),
          ),
          const SizedBox(height: 10),
          Text(
            res == 0
                ? "-"
                : NumberFormat.currency(
                        symbol: _getCurrencySymbol(to), decimalDigits: decimals)
                    .format(res),
            style: const TextStyle(
                color: primaryBlue,
                fontSize: 38,
                fontWeight: FontWeight.w900,
                letterSpacing: -1),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
