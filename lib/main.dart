import 'package:flutter/material.dart';
import 'package:influxdb_client/api.dart';
import 'package:intl/intl.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: DefaultTabController(
        length: 2,
        child: Scaffold(
          appBar: AppBar(
            bottom: TabBar(
              tabs: [
                Tab(
                  icon: Icon(Icons.analytics_outlined),
                  text: 'Registros',
                ),
                Tab(
                  icon: Icon(Icons.home_outlined),
                  text: 'Lista',
                ),
              ],
            ),
            title: Text("Registro de Datos"),
          ),
          body: TabBarView(
            children: [
              Registros(checkInfluxDBConnection),
              ListaWidget(),
            ],
          ),
        ),
      ),
    );
  }
}

class Registros extends StatefulWidget {
  final Function checkInfluxDBConnection;

  Registros(this.checkInfluxDBConnection);

  @override
  _RegistrosState createState() => _RegistrosState();
}

class _RegistrosState extends State<Registros> {
  String _message = '';

  @override
  void initState() {
    super.initState();
    _actualizarRegistros();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('Contenido de la pestaña de Registros'),
                SizedBox(height: 20),
                ElevatedButton(
                  onPressed: () async {
                    _actualizarRegistros();
                  },
                  child: Text('Actualizar registros'),
                ),
              ],
            ),
          ),
        ),
        Expanded(
          flex: 2,
          child: DataTableWidget(_message),
        ),
      ],
    );
  }

  Future<void> _actualizarRegistros() async {
    String resultMessage = await widget.checkInfluxDBConnection();
    setState(() {
      _message = resultMessage;
    });
  }
}

class ListaWidget extends StatefulWidget {
  @override
  _ListaWidgetState createState() => _ListaWidgetState();
}

class _ListaWidgetState extends State<ListaWidget> {
  DateTime? _selectedDate;
  TextEditingController _valorController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: EdgeInsets.all(16),
      children: [
        Text(
          'Llena los campos para registrar un nuevo dato',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        SizedBox(height: 20),
        TextFormField(
          controller: _valorController,
          decoration: InputDecoration(
            labelText: 'Ingresar valor',
            border: OutlineInputBorder(),
          ),
          keyboardType: TextInputType.number,
        ),
        SizedBox(height: 20),
        _getDatePickerEnabled(),
        SizedBox(height: 20),
        ElevatedButton(
          onPressed: () async {
            // Lógica para registrar el nuevo dato en InfluxDB
            await _registrarDato();
          },
          child: Text('Ingresar'),
        ),
      ],
    );
  }

  Widget _getDatePickerEnabled() {
    return InkWell(
      onTap: () async {
        final DateTime? pickedDate = await showDatePicker(
          context: context,
          initialDate: DateTime.now(),
          firstDate: DateTime(2000),
          lastDate: DateTime(2100),
        );

        if (pickedDate != null) {
          setState(() {
            _selectedDate = pickedDate;
          });
          print('Fecha seleccionada: $_selectedDate');
        }
      },
      child: InputDecorator(
        decoration: InputDecoration(labelText: 'Seleccionar fecha', enabled: true),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          mainAxisSize: MainAxisSize.max,
          children: <Widget>[
            Text(
              _selectedDate != null
                  ? DateFormat.yMMMd().format(_selectedDate!)
                  : 'No seleccionada',
              style: TextStyle(fontSize: 16),
            ),
            Icon(Icons.calendar_today),
          ],
        ),
      ),
    );
  }

  Future<void> _registrarDato() async {
    try {
      var client = InfluxDBClient(
        url: 'http://192.168.1.74:8086',
        token: 'NULrwvI8QpgLCHNHP9p0kQzAfPL0j2a31q79-xY5gonKl02we3tAhdCUfGbAg-xs0YG-Y8ooZNR4TXLA0lsnWg==',
        org: 'TEC Guasave',
        bucket: 'Test',
      );

      var writeApi = WriteService(client);

      var point = Point('h2o')
          .addField('valor', double.parse(_valorController.text))
          .time(_selectedDate ?? DateTime.now().toUtc());

      await writeApi.write(point).then((value) {
        print('Registro ingresado exitosamente');
        // Limpiar el campo de valor después de ingresar el registro
        _valorController.clear();
        setState(() {
          // Limpiar la fecha seleccionada después de ingresar el registro
          _selectedDate = null;
        });
      }).catchError((exception) {
        print("Error al ingresar el registro:");
        print(exception);
      });
    } catch (error) {
      print("Error al conectar a InfluxDB:");
      print(error);
    }
  }
}

class DataTableWidget extends StatelessWidget {
  final String message;

  DataTableWidget(this.message);

  @override
  Widget build(BuildContext context) {
    List<Map<String, dynamic>> data = [];

    if (message.contains('Conexión exitosa')) {
      var lines = message.split('\n');
      if (lines.length > 1) {
        for (var i = 1; i < lines.length - 1; i++) {
          var lineParts = lines[i].split(' ');
          if (lineParts.length >= 4) {
            var time = lineParts[2];
            var value = lineParts[3];
            data.add({'Time': time, 'Value': value});
          }
        }
      }
    }

    return data.isNotEmpty
        ? SingleChildScrollView(
      scrollDirection: Axis.vertical,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          columns: [
            DataColumn(label: Text('Time')),
            DataColumn(label: Text('Value')),
          ],
          rows: data.map((entry) {
            return DataRow(cells: [
              DataCell(Text(entry['Time'])),
              DataCell(Text(entry['Value'])),
            ]);
          }).toList(),
        ),
      ),
    )
        : Container();
  }
}



Future<String> checkInfluxDBConnection() async {
  try {
    var client = InfluxDBClient(
      url: 'http://192.168.1.74:8086',
      token: 'NULrwvI8QpgLCHNHP9p0kQzAfPL0j2a31q79-xY5gonKl02we3tAhdCUfGbAg-xs0YG-Y8ooZNR4TXLA0lsnWg==',
      org: 'TEC Guasave',
      bucket: 'Test',
    );

    var queryService = client.getQueryService();

    var recordStream = await queryService.query('''
      from(bucket: "Test")
      |> range(start: 0)
      |> filter(fn: (r) => r["_measurement"] == "h2o")
      |> aggregateWindow(every: 1m, fn: mean, createEmpty: false)
      |> yield(name: "mean")
      ''');

    var result = '';
    var count = 0;
    await recordStream.forEach((record) {
      result += 'record: ${count++} ${record['_time']} ${record['_value']}\n';
    });

    if (count > 0) {
      print(result);
      result = 'Conexión exitosa.\n' + result;
    } else {
      result = 'No se encontraron datos.';
    }

    client.close();
    return result;
  } catch (error) {
    return 'Error al conectar a InfluxDB: $error';
  }
}
