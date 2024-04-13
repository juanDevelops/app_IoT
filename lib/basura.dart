import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;


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
              // Contenido de la pestaña de Registros
              Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('Contenido de la pestaña de Registros'),
                    SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: () {
                        // Acción a realizar al presionar el botón
                        print('Botón "Actualizar registros" presionado');
                      },
                      child: Text('Actualizar registros'),
                    ),
                  ],
                ),
              ),
              // Contenido de la pestaña de Lista
              ListaWidget(), // Usamos un StatefulWidget separado para la pestaña de Lista
            ],
          ),
        ),
      ),
    );
  }
}

class ListaWidget extends StatefulWidget {
  @override
  _ListaWidgetState createState() => _ListaWidgetState();
}

class _ListaWidgetState extends State<ListaWidget> {
  DateTime? _selectedDate; // Variable para almacenar la fecha seleccionada

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
        _getDatePickerEnabled(), // Llamamos al método para mostrar el DatePicker
        SizedBox(height: 20),
        // Usamos Row para colocar los botones "Ingresar" y "Modificar" en la misma línea
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            Expanded(
              child: ElevatedButton(
                onPressed: () {
                  // Acción a realizar al presionar el botón "Ingresar"
                  print('Botón "Ingresar" presionado');
                },
                child: Text('Ingresar'),
              ),
            ),
            SizedBox(width: 10), // Espacio entre los botones
            Expanded(
              child: ElevatedButton(
                onPressed: () {
                  // Acción a realizar al presionar el botón "Modificar"
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
            _selectedDate = pickedDate; // Actualizamos la fecha seleccionada
          });
          print('Fecha seleccionada: $_selectedDate');
          // Aquí puedes almacenar la fecha seleccionada en una variable o realizar otras acciones necesarias
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




