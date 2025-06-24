import 'dart:convert';
import 'package:antiquewebemquiry/Constants/baseurl.dart';
import 'package:antiquewebemquiry/Global/location.dart';
import 'package:antiquewebemquiry/Global/username.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class MessagePage extends StatefulWidget {
  final int initialTabIndex;

  const MessagePage({super.key, required this.initialTabIndex});

  @override
  State<MessagePage> createState() => _MessagePageState();
}

class _MessagePageState extends State<MessagePage> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  String generalMessage = '';
  String vendorMessage = '';
  bool isLoading = true;

  final String location = Location.location; // You can make this dynamic
  final String email = Username.username; // You can make this dynamic

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this, initialIndex: widget.initialTabIndex);
    fetchMessages();
  }

  Future<void> fetchMessages() async {
    try {
      final marketUri = Uri.parse('$baseurl/Home/getMarketMessage?location=$location');
      final vendorUri = Uri.parse('$baseurl/Home/getVendorMessage?location=$location&email=$email');

      final marketResponse = await http.get(marketUri);
      final vendorResponse = await http.get(vendorUri);

      if (marketResponse.statusCode == 200 && vendorResponse.statusCode == 200) {
        final marketData = json.decode(marketResponse.body);
        final vendorData = json.decode(vendorResponse.body);

        setState(() {
          generalMessage = marketData['marketMessage']?.toString().trim() ?? '';
          vendorMessage = vendorData['vendorMessage']?.toString().trim() ?? '';
          isLoading = false;
        });
      } else {
        throw Exception('Failed to fetch data');
      }
    } catch (e) {
      setState(() {
        generalMessage = 'Error loading general message.';
        vendorMessage = 'Error loading vendor message.';
        isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final Size screenSize = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Messages',
          style: TextStyle(
            color: Colors.black,
            fontFamily: 'DM Sans',
            fontSize: 16,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.black87),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFFFF8500)))
          : Column(
              children: [
                Container(
                  color: Colors.white,
                  child: TabBar(
                    controller: _tabController,
                    labelColor: Colors.white,
                    unselectedLabelColor: const Color(0xFFFF8500),
                    indicator: const BoxDecoration(
                      color: Color(0xFFFF8500),
                    ),
                    indicatorSize: TabBarIndicatorSize.tab,
                    tabs: [
                      Tab(
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          decoration: BoxDecoration(
                            color: _tabController.index == 0 ? const Color(0xFFFF8500) : Colors.white,
                            borderRadius: BorderRadius.circular(0),
                          ),
                          child: const Text(
                            'General Message',
                            style: TextStyle(fontWeight: FontWeight.w500),
                          ),
                        ),
                      ),
                      Tab(
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          decoration: BoxDecoration(
                            color: _tabController.index == 1 ? const Color(0xFFFF8500) : Colors.white,
                            borderRadius: BorderRadius.circular(0),
                          ),
                          child: const Text(
                            'Message for Vendors',
                            style: TextStyle(fontWeight: FontWeight.w500),
                          ),
                        ),
                      ),
                    ],
                    onTap: (index) {
                      setState(() {});
                    },
                  ),
                ),
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      _buildMessageTab(screenSize, 'Message from Market', generalMessage),
                      _buildMessageTab(screenSize, 'Message for Vendors', vendorMessage),
                    ],
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildMessageTab(Size screenSize, String title, String message) {
    return Container(
      color: const Color(0xFFF1EDE8),
      child: ListView(
        children: [
          _buildMessageCard(
            title: title,
            time: '',
            message: message,
            isUnread: true,
          ),
        ],
      ),
    );
  }

  Widget _buildMessageCard({
    required String title,
    required String time,
    required String message,
    bool isUnread = false,
    bool showViewMore = true,
  }) {
    return Card(
      color: Colors.white,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
      child: InkWell(
        onTap: () {
          // Message tap action
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF2D3142),
                    ),
                  ),
                  const Spacer(),
                  Text(
                    time,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                message,
                style: const TextStyle(
                  fontSize: 14,
                  color: Color(0xFF2D3142),
                  height: 1.5,
                ),
              ),
              if (showViewMore)
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () {
                        // View more action
                      },
                      style: TextButton.styleFrom(
                        foregroundColor: const Color(0xFFFF8500),
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        minimumSize: Size.zero,
                      ),
                      child: const Text(''),
                    ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }
}
