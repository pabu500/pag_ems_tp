import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:html' as html;

import 'package:path_provider/path_provider.dart';

class WgtEbBillTenant extends StatefulWidget {
  const WgtEbBillTenant({
    super.key,
    required this.tenantIdStr,
    required this.tenenatName,
    required this.tenantLabel,
    required this.tenantAccountNumber,
  });

  final String tenantIdStr;
  final String tenenatName;
  final String tenantLabel;
  final String tenantAccountNumber;

  @override
  State<WgtEbBillTenant> createState() => _WgtEbBillTenantState();
}

class _WgtEbBillTenantState extends State<WgtEbBillTenant> {
  List<String> _ebTenantList = [];
  List<String> _filteredEbTenantList = [];
  String baseUrl = 'https://dev-eb-helper.evs.com.sg/api';
  // String baseUrl = 'http://localhost:6022/api';
  String fileListEndpoint = '/get_file_list';
  String downloadFileEndpoint = '/get_file';
  String tenantListEndpoint = '/get_tenant_list';
  String uploadFileEndpoint = '/upload_file';
  String deleteFileEndpoint = '/delete_file';
  String userId = 'admin';
  String? _selectedTenant;
  final TextEditingController _tenantController = TextEditingController();
  List<Map<String, dynamic>> pdfList = [];
  late Future<void> _getTenantListFuture;
  // late List<bool> _selectedPdf;

  Future<void> getTenantListFuture() async {
    if (_ebTenantList.isNotEmpty) {
      _ebTenantList = [];
    }

    final Map<String, dynamic> body = {
      'user_id': userId,
    };

    var response;

    try {
      response = await http.post(
        Uri.parse(baseUrl + tenantListEndpoint),
        body: jsonEncode(body),
        headers: {
          'Content-Type': 'application/json',
        },
      );
    } catch (e) {
      if (kDebugMode) {
        print('eb billing release: error getting tenant list: $e');
      }
    }

    if (response.statusCode == 200) {
      var data = jsonDecode(response.body);

      if (data['data'] == null) {
        if (kDebugMode) {
          print('eb billing release: no data');
          return;
        }
      }

      List<dynamic> tenantList = data['data'];
      for (Map<String, dynamic> tenant in tenantList) {
        if (!tenant.containsKey('folder_name')) {
          continue;
        }
        _ebTenantList.add(tenant['folder_name']);
      }
      setState(() {
        if (_selectedTenant == null) {
          _filteredEbTenantList = _ebTenantList;
        } else {
          _filteredEbTenantList = _ebTenantList
              .where((element) => element == _selectedTenant)
              .toList();
        }
      });
    }
  }

  Future<void> getPdfList(String tenantId) async {
    pdfList = [];
    var url = baseUrl + fileListEndpoint;

    final Map<String, dynamic> body = {
      'tenant_id': tenantId,
    };

    try {
      final response = await http.post(
        Uri.parse(url),
        body: jsonEncode(body),
        headers: {
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;

        if (!data.containsKey("files")) {
          if (kDebugMode) {
            const snackBar = SnackBar(
                duration: Duration(milliseconds: 1000),
                content: Text("No files found"));
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(snackBar);
            }
            return;
          }
        }

        final List<Map<String, dynamic>> files =
            (data['files'] as List<dynamic>)
                .map((item) => item as Map<String, dynamic>)
                .toList();

        if (files.isEmpty) {
          return;
        }

        files.sort((a, b) => b['filename'].compareTo(a['filename']));

        for (Map<String, dynamic> file in files) {
          if (!file.containsKey("filename")) {
            continue;
          }

          final pdfUrl = file['filename'] as String;

          setState(() {
            pdfList.add({'filename': pdfUrl, 'selected': false});
            // _selectedPdf = List.filled(pdfList.length, false);
          });
        }
      } else {
        // Handle non-200 status codes
      }
    } catch (e) {
      // Handle errors
      if (kDebugMode) {
        print(e);
      }
    }
  }

  Future<void> uploadPdf() async {
    final input = html.FileUploadInputElement();
    input.accept = '.pdf';
    input.multiple = true;

    // Prepare the request to the server
    var url = baseUrl + uploadFileEndpoint; // Replace with your API endpoint

    var request = http.MultipartRequest(
      'POST',
      Uri.parse(url), // Replace with your backend API URL
    );

    input.onChange.listen((e) async {
      final files = input.files;
      if (files == null || files.isEmpty) {
        if (kDebugMode) {
          print('No files selected');
        }
        return;
      }

      if (files.length > 20) {
        if (kDebugMode) {
          print('Max 20 files can be uploaded at a time');
        }
        return;
      }

      final futures = <Future<void>>[];

      // Add files to the request
      for (var file in files) {
        if (file.type != 'application/pdf') {
          const snackBar =
              SnackBar(content: Text("Only PDF files are allowed"));
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(snackBar);
          }
          return;
        }

        final reader = html.FileReader();
        final future = Completer<void>();

        reader.onLoadEnd.listen((e) {
          final fileBytes = reader.result as Uint8List;

          request.files.add(http.MultipartFile.fromBytes(
            'files', // This key should match the backend expectation
            fileBytes,
            filename: file.name,
          ));

          future.complete();
        });

        reader.readAsArrayBuffer(file);
        futures.add(future.future);
      }

      // Wait for all file reads to complete
      await Future.wait(futures);

      // Adding a map as additional data (metadata)
      Map<String, dynamic> metadata = {
        "file_count": files.length.toString(),
      };

      // Add each entry in metadata as a field
      metadata.forEach((key, value) {
        request.fields[key] = value;
      });

      late final http.StreamedResponse response;

      try {
        response = await request.send();
      } catch (e) {
        if (kDebugMode) {
          print('Upload failed with error: $e');
        }
      }

      if (response.statusCode == 200) {
        Map<String, dynamic> responseBody =
            jsonDecode(await response.stream.bytesToString());
        String message = '';
        List<Map<String, dynamic>> dataList = [];

        if (responseBody.containsKey("success") &&
            responseBody['success'] &&
            responseBody['error'] == null) {
          dataList = (responseBody['data'] as List<dynamic>)
              .map((item) => item as Map<String, dynamic>)
              .toList();

          for (Map<String, dynamic> data in dataList) {
            if (data.containsKey("success") && data['success']) {
              continue;
            }

            if (!data.containsKey("filename") || !data.containsKey("message")) {
              message += "no filename or message found\n";
              continue;
            }

            message += data['filename'] + ": " + data['message'] + '\n';
          }

          message += "Upload successful";
        } else {
          Map<String, dynamic> error =
              responseBody['error'] as Map<String, dynamic>;
          if (error['message'] == null) {
            message = "Upload failed. No error message found";
          } else {
            message = error['message'].toString();
          }
        }

        final snackBar = SnackBar(
          content: Text(message),
          duration: const Duration(seconds: 4),
        );

        _getTenantListFuture = getTenantListFuture();
        if (_selectedTenant != null) {
          await updatePdfList(_selectedTenant!);
        }
        setState(() {});
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(snackBar);
        }
      }
    });

    input.click();
  }

  Future<void> _downloadPdf(String filename, String tenantId) async {
    var url = baseUrl + downloadFileEndpoint;

    final Uri uri = Uri.parse(url);
    late final http.Response response;

    try {
      response = await http.post(uri,
          body: jsonEncode({
            'filename': filename,
            'tenant_id': tenantId,
          }),
          headers: {
            'Content-Type': 'application/json',
          });
    } catch (e) {
      if (kDebugMode) {
        print('Failed to download file: $e');
      }
      return;
    }

    if (response.statusCode == 200) {
      if (response.bodyBytes.isEmpty) {
        const snackBar = SnackBar(content: Text("No data found"));
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(snackBar);
        }
        return;
      }

      final Uint8List bytes = response.bodyBytes; // Get the binary data

      if (kIsWeb) {
        final blob = html.Blob([bytes]);
        final url = html.Url.createObjectUrlFromBlob(blob);
        html.AnchorElement(href: url)
          ..setAttribute("download", filename)
          ..click();
        html.Url.revokeObjectUrl(url);
      } else {
        final Directory directory = await getApplicationDocumentsDirectory();
        final String filePath = '${directory.path}/$filename';
        final File file = File(filePath);

        await file.writeAsBytes(bytes);
      }

      const snackBar = SnackBar(
          duration: Duration(milliseconds: 1000),
          content: Text('File downloaded successfully'));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(snackBar);
      }
    } else {
      String? header = response.headers['error'];
      header ??= 'Failed to download file';
      final snackBar = SnackBar(content: Text(header));

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(snackBar);
      }
    }
  }

  void filterDropdownEntries(String query) {
    setState(() {
      _filteredEbTenantList = _ebTenantList
          .where((tenant) => tenant.toLowerCase().contains(query.toLowerCase()))
          .toList();
    });
  }

  Future<void> updatePdfList(String tenantId) async {
    getPdfList(tenantId);
    if (pdfList.isEmpty) {
      return;
    }
    // setState(() {
    //   _selectedPdf = List.filled(pdfList.length, false);
    // });
  }

  Future<void> deletePdf(List<String> fileList, String userId) async {
    var url = baseUrl + deleteFileEndpoint;
    int success = 0;
    int failure = 0;
    SnackBar snackBar;

    for (String filename in fileList) {
      var response;
      final Map<String, dynamic> body = {
        'filename': filename,
        'user_id': userId,
      };

      try {
        response = await http.post(
          Uri.parse(url),
          body: jsonEncode(body),
          headers: {
            'Content-Type': 'application/json',
          },
        );
        // Refresh the list of PDFs
      } catch (e) {
        final snackBar = SnackBar(content: Text(e.toString()));
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(snackBar);
        }
      }

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;

        if (data.containsKey("success") &&
            data['success'] &&
            data['error'] == null) {
          success++;
        } else {
          failure++;
        }
      } else {
        String message =
            (jsonDecode(response.body) as Map<String, dynamic>)['error'] ??
                'Failed to delete file';

        snackBar = SnackBar(
            duration: const Duration(milliseconds: 1000),
            content: Text(message));

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(snackBar);
        }
        return;
      }
    }

    if (success > 0) {
      snackBar = SnackBar(
          duration: const Duration(milliseconds: 2000),
          content: Text('$success File(s) deleted successfully'));

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(snackBar);
      }
    }

    if (failure > 0) {
      snackBar = SnackBar(
          duration: const Duration(milliseconds: 2000),
          content: Text('$failure File(s) failed to delete'));

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(snackBar);
      }
    }
  }

  Future<void> _showConfirmationDialog(
      BuildContext context, List<String> files, String tenantId) async {
    String filename = files.length == 1
        ? files[0]
        : files.length == pdfList.length
            ? 'all'
            : '${files.length} files selected';

    return showDialog<void>(
      context: context,
      barrierDismissible: false, // User must tap button to dismiss
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Confirm Deletion'),
          content: Text('Are you sure you want to delete $filename ?'),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop(); // Close the dialog
              },
            ),
            TextButton(
              child: const Text('Delete'),
              onPressed: () async {
                Navigator.of(context).pop(); // Close the dialog
                if (!_ebTenantList.contains(tenantId)) {
                  return;
                }
                await deletePdf(files, userId);

                _getTenantListFuture = getTenantListFuture();
                await updatePdfList(tenantId);
                // setState(() {});
              },
            ),
          ],
        );
      },
    );
  }

  void _filterTenantList() {
    String query = _tenantController.text.toLowerCase();
    setState(() {
      _filteredEbTenantList = _ebTenantList
          .where((tenant) => tenant.toLowerCase().contains(query.toLowerCase()))
          .toList();
    });
  }

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    _selectedTenant = null;
    _filteredEbTenantList = _ebTenantList;
    _getTenantListFuture = getTenantListFuture();
    _tenantController.addListener(_filterTenantList);
    // _tenantController.addListener(() {
    //   filterDropdownEntries(_tenantController.text);
    // });
  }

  @override
  void dispose() {
    super.dispose();
    _tenantController.dispose();
  }

  @override
  Widget build(BuildContext context) {
    double screenHeight = MediaQuery.of(context).size.height;
    return SingleChildScrollView(
        child: SizedBox(
            width: MediaQuery.of(context).size.width,
            height: screenHeight > 120 ? screenHeight - 120 : screenHeight,
            child: FutureBuilder(
                future: _getTenantListFuture,
                builder: (BuildContext context, AsyncSnapshot snapshot) {
                  switch (snapshot.connectionState) {
                    case ConnectionState.waiting:
                      if (kDebugMode) {
                        print('eb billing release: pulling data');
                      }
                      return const Center(
                        child: CircularProgressIndicator(),
                      );
                    default:
                      if (snapshot.hasError) {
                        return Text('Error: ${snapshot.error}');
                      } else {
                        return completedWidget();
                      }
                  }
                })));
  }

  Widget completedWidget() {
    return Padding(
        padding: const EdgeInsets.all(16),
        child: Container(
          // height: MediaQuery.of(context).size.height,
          padding: const EdgeInsets.symmetric(horizontal: 10),
          // decoration: BoxDecoration(
          //   border:
          //       Border.all(color: Theme.of(context).primaryColor, width: 3),
          //   borderRadius: BorderRadius.circular(8),
          // ),
          width: MediaQuery.of(context).size.width,
          child: Column(
            children: [
              getBatchControlWidget(),
              const SizedBox(height: 20),
              getPdfListWidget(),
            ],
          ),
        ));
  }

  Widget getBatchControlWidget() {
    double screenHeight = MediaQuery.of(context).size.height;
    return Container(
      height: screenHeight > 100 ? 100 : screenHeight,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      alignment: Alignment.centerLeft,
      decoration: BoxDecoration(
        border: Border.all(color: Theme.of(context).hintColor, width: 1),
        borderRadius: BorderRadius.circular(5.0),
      ),
      child: Row(
        children: [
          getSearchWidget(),
          // const SizedBox(width: 10),
          getActionPdfWidget(),
        ],
      ),
    );
  }

  Widget getSearchWidget() {
    return Container(
        child: Row(
      children: [
        DropdownMenu(
          enabled: true,
          width: 200,
          controller: _tenantController,
          dropdownMenuEntries: _filteredEbTenantList
              .where((tenant) => tenant
                  .toLowerCase()
                  .contains(_tenantController.text.toLowerCase()))
              .map((tenant) => DropdownMenuEntry<String>(
                    value: tenant,
                    label: tenant,
                  ))
              .toList(),
          onSelected: (String? value) {
            _tenantController.text = value!;
          },
          menuStyle: MenuStyle(
            elevation: const WidgetStatePropertyAll<double>(8.0),
            shadowColor: WidgetStatePropertyAll<Color>(
                Theme.of(context).colorScheme.primary),
            backgroundColor:
                WidgetStatePropertyAll<Color>(Theme.of(context).canvasColor),
            surfaceTintColor: const WidgetStatePropertyAll(Colors.transparent),
          ),
          inputDecorationTheme: const InputDecorationTheme(
            enabledBorder: UnderlineInputBorder(
              borderSide: BorderSide(
                color: Colors.grey,
                width: 1,
                style: BorderStyle.solid,
              ),
            ),
            focusedBorder: UnderlineInputBorder(
              borderSide: BorderSide(
                color: Colors.blue,
                width: 1,
                style: BorderStyle.solid,
              ),
            ),
            fillColor: Colors.transparent,
            filled: true,
            contentPadding: EdgeInsets.symmetric(horizontal: 0.0),
          ),
        ),
        const SizedBox(width: 18),
        IconButton(
          tooltip: 'Search',
          onPressed: _tenantController.text == ''
              ? null
              : () async {
                  pdfList = [];

                  // if (_tenantController.text.isEmpty) {
                  //   return;
                  // }

                  // if (_ebTenantList.isEmpty) {
                  //   return;
                  // }

                  // if (!_ebTenantList.contains(_tenantController.text)) {
                  //   return;
                  // }

                  _selectedTenant = _tenantController.text;

                  if (_ebTenantList.contains(_selectedTenant)) {
                    await updatePdfList(_selectedTenant!);
                  } else {
                    SnackBar snackBar = const SnackBar(
                      content: Text('Tenant does not exist'),
                      duration: Duration(seconds: 1),
                    );
                    ScaffoldMessenger.of(context).showSnackBar(snackBar);
                    setState(() {});
                  }

                  // setState(() {});
                },
          icon: Icon(
            Icons.search,
            size: 21,
            color: _tenantController.text == ''
                ? Theme.of(context).hintColor
                : Theme.of(context).colorScheme.primary,
          ),
        ),
      ],
    ));
  }

  Widget getActionPdfWidget() {
    return Container(
        padding: const EdgeInsets.symmetric(horizontal: 10),
        alignment: Alignment.centerLeft,
        // decoration: BoxDecoration(
        //   border: Border.all(color: Theme.of(context).primaryColor, width: 3),
        //   borderRadius: BorderRadius.circular(8),
        // ),
        child: Row(
          children: [
            IconButton(
              tooltip: 'Upload PDF',
              onPressed: uploadPdf,
              icon: Icon(
                Icons.cloud_upload,
                size: 21,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
            const SizedBox(width: 20),
          ],
        ));
  }

  Widget getPdfListWidget() {
    return Expanded(
      // height: MediaQuery.of(context).size.height - 200,
      child: _selectedTenant != null
          ? Container(
              alignment: Alignment.topCenter,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              height: MediaQuery.of(context).size.height > 450
                  ? 450
                  : MediaQuery.of(context).size.height,
              decoration: BoxDecoration(
                border:
                    Border.all(color: Theme.of(context).hintColor, width: 1),
                borderRadius: BorderRadius.circular(5.0),
              ),
              child: SingleChildScrollView(
                child: Column(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      pdfList.isNotEmpty
                          ? SizedBox(
                              width: MediaQuery.of(context).size.width - 40,
                              height: 30,
                              child: Row(
                                children: [
                                  SizedBox(
                                    width: 150,
                                    child: Text(
                                      pdfList.isEmpty ||
                                              pdfList.every((element) =>
                                                  !element['selected'])
                                          ? 'No PDFs selected'
                                          : pdfList.every((element) =>
                                                  element['selected'])
                                              ? 'All PDFs selected'
                                              : '${pdfList.where((element) => element['selected']).length} PDFs selected',
                                    ),
                                  ),
                                  const SizedBox(
                                    width: 40,
                                  ),
                                  pdfList.every(
                                          (element) => !element['selected'])
                                      ? const SizedBox.shrink()
                                      : InkWell(
                                          onTap: () {
                                            if (_selectedTenant == null ||
                                                !_ebTenantList.contains(
                                                    _selectedTenant)) {
                                              if (kDebugMode) {
                                                print('tenant does not exist');
                                              }
                                              return;
                                            }
                                            //check if no pdf is selected
                                            if (pdfList.every((element) =>
                                                !element['selected'])) {
                                              return;
                                            }
                                            if (pdfList.every((element) =>
                                                element['selected'])) {
                                              _showConfirmationDialog(
                                                  context,
                                                  pdfList
                                                      .map((e) => e['filename']
                                                          as String)
                                                      .toList(),
                                                  _selectedTenant!);
                                            } else {
                                              _showConfirmationDialog(
                                                  context,
                                                  pdfList
                                                      .asMap()
                                                      .entries
                                                      .where((element) =>
                                                          pdfList[element.key]
                                                              ['selected'])
                                                      .map((e) =>
                                                          e.value['filename']
                                                              as String)
                                                      .toList(),
                                                  _selectedTenant!);
                                            }
                                          },
                                          child: Container(
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 10, vertical: 5),
                                            decoration: BoxDecoration(
                                              color: Theme.of(context)
                                                  .colorScheme
                                                  .primary,
                                              borderRadius:
                                                  BorderRadius.circular(5.0),
                                            ),
                                            child: const Text('Delete PDFs'),
                                          ),
                                        ),
                                ],
                              ))
                          : const SizedBox.shrink(),
                      const SizedBox(height: 0),
                      SizedBox(
                        width: MediaQuery.of(context).size.width - 40,
                        child: pdfList.isNotEmpty
                            ? DataTable(
                                dividerThickness: 0.2,
                                columns: [
                                  DataColumn(
                                      label: Checkbox(
                                          value: pdfList.every(
                                              (element) => element['selected']),
                                          onChanged: (value) {
                                            setState(() {
                                              for (var element in pdfList) {
                                                element['selected'] = value;
                                              }
                                            });
                                          })),
                                  const DataColumn(
                                      label: Expanded(
                                    child: Text('PDF'),
                                  )),
                                  const DataColumn(label: Text('Delete')),
                                  const DataColumn(label: Text('Download'))
                                ],
                                rows: List.generate(pdfList.length, (index) {
                                  final filename =
                                      pdfList[index]['filename']?.toString() ??
                                          '';
                                  return DataRow(
                                    cells: [
                                      DataCell(
                                        SizedBox(
                                          child: Checkbox(
                                            value: pdfList[index]['selected'],
                                            onChanged: (bool? value) {
                                              setState(() {
                                                pdfList[index]['selected'] =
                                                    value ??
                                                        false; // Update when checkbox is clicked
                                              });
                                            },
                                          ),
                                        ),
                                      ),
                                      DataCell(SizedBox(
                                        width:
                                            MediaQuery.of(context).size.width -
                                                60 -
                                                200 -
                                                60 -
                                                100 -
                                                40 -
                                                40 -
                                                200,
                                        child: Row(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          mainAxisAlignment:
                                              MainAxisAlignment.start,
                                          children: [
                                            Flexible(
                                              fit: FlexFit.tight,
                                              child: Text(
                                                filename,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                          ],
                                        ),
                                      )),
                                      DataCell(SizedBox(
                                        width: 40,
                                        child: IconButton(
                                          color: Colors.red,
                                          // hoverColor: Colors.transparent,
                                          icon: const Icon(
                                            Icons.delete,
                                          ),
                                          onPressed: () =>
                                              _showConfirmationDialog(context,
                                                  [filename], _selectedTenant!),
                                          tooltip: 'Delete',
                                          focusColor: Colors.transparent,
                                        ),
                                      )),
                                      DataCell(SizedBox(
                                        width: 60,
                                        child: IconButton(
                                          color: Theme.of(context)
                                              .colorScheme
                                              .primary,
                                          icon:
                                              const Icon(Icons.cloud_download),
                                          onPressed: () => _downloadPdf(
                                              filename, _selectedTenant!),
                                          tooltip: 'Download',
                                        ),
                                      )),
                                    ],
                                  );
                                }),
                              )
                            : _selectedTenant != null
                                ? const Center(
                                    child: Text('No Files Found'),
                                  )
                                : const SizedBox.shrink(),
                      ),
                    ]),
              ),
            )
          : const SizedBox.shrink(),
    );
  }
}
