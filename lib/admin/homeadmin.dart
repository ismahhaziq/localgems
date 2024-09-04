import 'package:flutter/material.dart';
import 'package:commerce_yt/admin/managecomplaint/managecomplaint.dart';
import 'package:commerce_yt/admin/manageuser/manageuser.dart';
import 'package:commerce_yt/admin/manageplace/manageplace.dart';
import 'package:commerce_yt/admin/manageplace/approval/manageapproval.dart';
import 'nav_bar.dart';

class HomeAdmin extends StatefulWidget {
  @override
  _HomeAdminState createState() => _HomeAdminState();
}

class _HomeAdminState extends State<HomeAdmin> {
  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        bool shouldExit = await showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: Text('Exit App'),
            content: Text('Are you sure you want to exit the app?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: Text('No'),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: Text('Yes'),
              ),
            ],
          ),
        );
        return shouldExit;
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            'Admin Dashboard',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          automaticallyImplyLeading: false,
          backgroundColor: Color(0xFF7472E0),
          centerTitle: true,
        ),
        body: SafeArea(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Center(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildDashboardItem(
                      context,
                      'Total Complaint',
                      'Click to manage complaints',
                      ManageComplaint(),
                    ),
                    SizedBox(height: 20),
                    _buildDashboardItem(
                      context,
                      'Total User',
                      'Click to manage users',
                      ManageUser(),
                    ),
                    SizedBox(height: 20),
                    _buildDashboardItem(
                      context,
                      'Total Infamous Local Place',
                      'Click to manage places',
                      ManagePlace(),
                    ),
                    SizedBox(height: 20),
                    _buildDashboardItem(
                      context,
                      'Approval Place',
                      'Click to manage approval place',
                      AdminPlaceApproval(),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        bottomNavigationBar: NavBar(currentIndex: 0),
      ),
    );
  }

  Widget _buildDashboardItem(
      BuildContext context, String title, String subtitle, Widget navigateTo) {
    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => navigateTo),
        );
      },
      child: Container(
        padding: EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.5),
              spreadRadius: 2,
              blurRadius: 5,
              offset: Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          children: [
            Text(
              title,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Color(0xFF7472E0),
              ),
            ),
            SizedBox(height: 10),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
