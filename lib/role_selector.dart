// import 'package:flutter/material.dart';
// import 'user_config.dart';
// // import 'package:intl/intl.dart';

// class RoleSelector extends StatefulWidget {
//   final VoidCallback onDone;
//   const RoleSelector({super.key, required this.onDone});

//   @override
//   State<RoleSelector> createState() => _RoleSelectorState();
// }

// class _RoleSelectorState extends State<RoleSelector> {
//   String _role = "user";
//   final TextEditingController _nameController = TextEditingController();

//   Future<void> _save() async {
//     final name = _nameController.text.trim();
//     if (name.isEmpty) return;
//     await UserConfig.setRole(_role, name);
//     widget.onDone();
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(title: const Text("Select Role")),
//       body: Padding(
//         padding: const EdgeInsets.all(16),
//         child: Column(
//           children: [
//             TextField(
//               controller: _nameController,
//               decoration: const InputDecoration(labelText: "Enter your name"),
//             ),
//             const SizedBox(height: 20),
//             DropdownButton<String>(
//               value: _role,
//               items: const [
//                 DropdownMenuItem(value: "user", child: Text("Normal User")),
//                 DropdownMenuItem(value: "helper", child: Text("Helper / Gov")),
//               ],
//               onChanged: (v) => setState(() => _role = v!),
//             ),
//             const SizedBox(height: 20),
//             ElevatedButton(onPressed: _save, child: const Text("Continue")),
//           ],
//         ),
//       ),
//     );
//   }
// }

import 'package:flutter/material.dart';
import 'user_config.dart';

class RoleSelector extends StatefulWidget {
  final VoidCallback onDone;
  const RoleSelector({super.key, required this.onDone});

  @override
  State<RoleSelector> createState() => _RoleSelectorState();
}

class _RoleSelectorState extends State<RoleSelector> {
  String _role = "";
  final TextEditingController _nameController = TextEditingController();

  Future<void> _save() async {
    final name = _nameController.text.trim();
    if (name.isEmpty || _role.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please select role & enter name")),
      );
      return;
    }
    await UserConfig.setRole(_role, name);
    print("Save success for role=$_role, name=$name");
    widget.onDone();
  }

  Widget _buildRoleButton({
    required String role,
    required String label,
    required IconData icon,
    required Color color,
  }) {
    final isSelected = _role == role;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _role = role),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          margin: const EdgeInsets.symmetric(horizontal: 8),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: isSelected ? color.withOpacity(0.9) : Colors.grey[200],
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isSelected ? color : Colors.grey,
              width: 2,
            ),
            boxShadow: isSelected
                ? [BoxShadow(color: color.withOpacity(0.4), blurRadius: 8)]
                : [],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 50, color: isSelected ? Colors.white : color),
              const SizedBox(height: 10),
              Text(
                label,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: isSelected ? Colors.white : Colors.black87,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Select Role")),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const Text(
              "Choose Your Role",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),

            // Role buttons
            Row(
              children: [
                _buildRoleButton(
                  role: "user",
                  label: "Normal User",
                  icon: Icons.person,
                  color: Colors.blue,
                ),
                _buildRoleButton(
                  role: "helper",
                  label: "Helper / Gov",
                  icon: Icons.volunteer_activism,
                  color: Colors.green,
                ),
              ],
            ),

            const SizedBox(height: 30),

            // Name input
            TextField(
              controller: _nameController,
              decoration: InputDecoration(
                labelText: "Enter your name",
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                prefixIcon: const Icon(Icons.badge),
              ),
            ),

            const SizedBox(height: 30),

            // Continue button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _save,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text("Continue", style: TextStyle(fontSize: 18)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
