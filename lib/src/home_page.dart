import 'dart:convert';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:googleapis_auth/auth_io.dart';
import 'package:http/http.dart' as http;

Future<Map<String, dynamic>> obtainCredentials(PlatformFile serviceAccountFile) async {
  var accountCredentials = ServiceAccountCredentials.fromJson(jsonDecode(
    await serviceAccountFile.xFile.readAsString(),
  ));
  List<String> scopes = ["https://www.googleapis.com/auth/firebase.messaging"];

  var client = http.Client();
  AccessCredentials accessCredential = await obtainAccessCredentialsViaServiceAccount(
    accountCredentials,
    scopes,
    client,
  );

  client.close();
  return accessCredential.toJson();
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  TextEditingController textEditingController = TextEditingController();
  PlatformFile? serviceAccountFile;
  Map<String, dynamic>? credential;

  Future<void> pickFile() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles();
    if (result != null) {
      serviceAccountFile = result.files.first;
      textEditingController.text = serviceAccountFile!.xFile.path;
      setState(() {});
    }
  }

  Future generateCredential() async {
    final result = await compute(obtainCredentials, serviceAccountFile!);
    setState(() {
      credential = result;
    });
  }

  @override
  void dispose() {
    textEditingController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("FCM Token Retriever"),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            TextField(
              readOnly: true,
              controller: textEditingController,
              decoration: InputDecoration(
                hintText: "Service account",
                suffixIcon: IconButton(
                  icon: const Icon(Icons.file_upload),
                  onPressed: pickFile,
                ),
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: serviceAccountFile != null ? generateCredential : null,
              child: const Text("Generate"),
            ),
            if (credential != null) ...[
              const SizedBox(height: 24),
              SelectableText(getPrettyJSONString(credential)),
              ElevatedButton(
                onPressed: () {
                  var token = credential?["accessToken"]?["data"] ?? "";
                  Clipboard.setData(ClipboardData(text: token));
                },
                child: const Text("Copy Token"),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

String getPrettyJSONString(jsonObject) {
  var encoder = const JsonEncoder.withIndent("     ");
  return encoder.convert(jsonObject);
}
