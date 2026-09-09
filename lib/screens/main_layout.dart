import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../main.dart';
import 'agenda_screen.dart';
import 'clientes_screen.dart';
import 'finanzas_screen.dart';
import 'perfil_screen.dart';

class MainLayout extends StatefulWidget {
  const MainLayout({super.key});

  @override
  State<MainLayout> createState() => _MainLayoutState();
}

class _MainLayoutState extends State<MainLayout> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('usuarios')
          .doc(user?.uid)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final userData = snapshot.data?.data() as Map<String, dynamic>?;
        final String rol = userData?['rol'] ?? 'barbero';

        final pages = _getPagesForRole(rol);
        final navItems = _getNavItemsForRole(rol);

        return Scaffold(
          body: pages[_selectedIndex >= pages.length ? 0 : _selectedIndex],
          bottomNavigationBar: BottomNavigationBar(
            currentIndex: _selectedIndex >= pages.length ? 0 : _selectedIndex,
            onTap: (index) => setState(() => _selectedIndex = index),
            type: BottomNavigationBarType.fixed,
            items: navItems,
          ),
        );
      },
    );
  }

  List<Widget> _getPagesForRole(String rol) {
    if (rol == 'admin') {
      return [
        HomeScreen(
          onIrAAgenda: () => setState(() => _selectedIndex = 1),
          onIrAFinanzas: () => setState(() => _selectedIndex = 3),
        ),
        const AgendaScreen(),
        const ClientesScreen(),
        const FinanzasScreen(),
        PerfilScreen(rol: rol),
      ];
    } else {
      return [
        const AgendaScreen(),
        const ClientesScreen(),
        PerfilScreen(rol: rol),
      ];
    }
  }

  List<BottomNavigationBarItem> _getNavItemsForRole(String rol) {
    if (rol == 'admin') {
      return const [
        BottomNavigationBarItem(
          icon: Icon(Icons.home),
          label: 'Inicio',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.calendar_today),
          label: 'Agenda',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.people),
          label: 'Clientes',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.attach_money),
          label: 'Finanzas',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.person),
          label: 'Perfil',
        ),
      ];
    } else {
      return const [
        BottomNavigationBarItem(
          icon: Icon(Icons.calendar_today),
          label: 'Agenda',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.people),
          label: 'Clientes',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.person),
          label: 'Perfil',
        ),
      ];
    }
  }
}