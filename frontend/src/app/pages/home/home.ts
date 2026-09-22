import { Component } from '@angular/core';
import { RouterLink } from '@angular/router';

@Component({
  selector: 'app-home',
  imports: [RouterLink],
  templateUrl: './home.html',
  styleUrl: './home.css'
})
export class Home {
  protected readonly year = new Date().getFullYear();

  protected readonly features = [
    {
      icon: '💸',
      title: 'Ingresos y gastos',
      description: 'Registrá tus movimientos y organizalos por categorías con color e ícono.'
    },
    {
      icon: '📊',
      title: 'Presupuestos',
      description: 'Definí límites mensuales por categoría y seguí tu progreso en tiempo real.'
    },
    {
      icon: '📈',
      title: 'Insights mensuales',
      description: 'Visualizá balances y tendencias de gasto mes a mes, sin planillas.'
    },
    {
      icon: '🏦',
      title: 'Múltiples cuentas',
      description: 'Bancos, efectivo, tarjetas: todas tus cuentas en un solo lugar.'
    },
    {
      icon: '🔁',
      title: 'Servicios recurrentes',
      description: 'Suscripciones y facturas periódicas, con recordatorio de vencimiento.'
    },
    {
      icon: '📄',
      title: 'Exportar a PDF',
      description: 'Sacá tus estadísticas y movimientos en PDF cuando los necesites.'
    }
  ];
}
