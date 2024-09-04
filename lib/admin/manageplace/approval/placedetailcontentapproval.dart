import 'package:flutter/material.dart';
import 'package:commerce_yt/admin/manageplace/placedetail/place_description.dart';

class PlaceDetailsContentApproval extends StatelessWidget {
  final String placeId;
  final Map<String, dynamic> placeData;
  final String? userId;

  PlaceDetailsContentApproval({
    required this.placeId,
    required this.placeData,
    required this.userId,
  });

  void _showImageDialog(BuildContext context, String imageUrl) {
    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: EdgeInsets.all(10),
          child: GestureDetector(
            onTap: () {
              Navigator.of(context).pop();
            },
            child: InteractiveViewer(
              child: Image.network(imageUrl),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    var hours = placeData['hours'] as Map<String, dynamic>;

    return CustomScrollView(
      slivers: [
        SliverAppBar(
          expandedHeight: 350.0,
          floating: false,
          pinned: true,
          flexibleSpace: LayoutBuilder(
            builder: (BuildContext context, BoxConstraints constraints) {
              double top = constraints.biggest.height;
              return FlexibleSpaceBar(
                title: top <= 120
                    ? Text(
                        placeData['placeName'],
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                        ),
                      )
                    : null,
                background: Stack(
                  children: [
                    PageView.builder(
                      controller: PageController(),
                      itemBuilder: (context, index) {
                        final imageUrl = placeData['imageURLs']
                            [index % placeData['imageURLs'].length];
                        return GestureDetector(
                          onTap: () {
                            _showImageDialog(context, imageUrl);
                          },
                          child: Image.network(
                            imageUrl,
                            fit: BoxFit.cover,
                            width: double.infinity,
                            height: double.infinity,
                          ),
                        );
                      },
                    ),
                    Positioned(
                      left: 20,
                      top: 50,
                      child: GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.black54,
                            shape: BoxShape.circle,
                          ),
                          padding: EdgeInsets.all(8),
                          child: Icon(
                            Icons.arrow_back,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
        SliverList(
          delegate: SliverChildListDelegate([
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(height: 16),
                  Divider(height: 1, thickness: 1),
                  SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          placeData['placeName'],
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 8),
                  PlaceDescription(
                    hours: hours,
                    placeData: placeData,
                  ),
                ],
              ),
            ),
          ]),
        ),
      ],
    );
  }
}
