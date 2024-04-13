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
                    String resultMessage = await widget.checkInfluxDBConnection();
                    setState(() {
                      _message = resultMessage;
                    });
                  },
                  child: Text('Actualizar registros'),
                ),
                SizedBox(height: 20),
                Text(_message),
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
}

class ListaWidget extends StatefulWidget {
  @override
  _ListaWidgetState createState() => _ListaWidgetState();
}

class _ListaWidgetState extends State<ListaWidget> {
  DateTime? _selectedDate;

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
          decoration: InputDecoration(
            labelText: 'Ingresar valor',
            border: OutlineInputBorder(),
          ),
          keyboardType: TextInputType.number,
        ),
        SizedBox(height: 20),
        _getDatePickerEnabled(),
        SizedBox(height: 20),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            Expanded(
              child: ElevatedButton(
                onPressed: () {
                  print('Botón "Ingresar" presionado');
                },
                child: Text('Ingresar'),
              ),
            ),
            SizedBox(width: 10),
            Expanded(
              child: ElevatedButton(
                onPressed: () {
                  print('Botón "Modificar" presionado');
                },
                child: Text('Modificar'),
              ),
            ),
          ],
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
        var count = int.parse(lines[1].split(' ')[1]);
        count++;

        for (var i = 0; i < count; i++) {
          var lineParts = lines[i + 1].split(' ');
          if (lineParts.length >= 3) {
            var time = lineParts[2];
            var value = lineParts[3];
            data.add({'Time': time, 'Value': value});
          }
        }
      }
    }

    return data.isNotEmpty
        ? SingleChildScrollView(
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

