import 'package:flutter/material.dart';

import 'in_app_web_view_screen.dart';

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  @override
  Widget build(BuildContext context) {
    //TODO: url[2] onwards will not work sometimes. A blank screen will show up.
    List<String> urls = [
      "https://myaadhaar.uidai.gov.in/genricDownloadAadhaar", //0
      "https://www.google.com/", //1
      "https://rhreporting.nic.in/netiay/SECCReport/report_categorywiseseccverification.aspx", //2
      "https://pmaymis.gov.in/", //3
      "https://bhulekh.mahabhumi.gov.in/", //4
      "https://dlrc.delhigovt.nic.in/" //5
    ];
    return Scaffold(
      appBar: AppBar(
        title: const Text('WebViewBug'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            const Text('Green button will work but red button may not work.'),
            Expanded(
              child: ListView.builder(
                itemCount: urls.length,
                itemBuilder: (context, index) {
                  return Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: ElevatedButton(
                      onPressed: () => Navigator.pushNamed(
                        context,
                        InAppWebViewScreen.routeName,
                        arguments: urls[index],
                      ),
                      style: ElevatedButton.styleFrom(
                        primary: (index == 0 || index == 1)
                            ? Colors.green
                            : Colors.red,
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Text(" This will open ${urls[index]}"),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
