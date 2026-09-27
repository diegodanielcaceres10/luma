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
      icon: 'flow',
      title: 'Ingresos y gastos',
      description: 'Registrá tus movimientos y organizalos por categorías con color e ícono.'
    },
    {
      icon: 'bar-chart',
      title: 'Presupuestos',
      description: 'Definí límites mensuales por categoría y seguí tu progreso en tiempo real.'
    },
    {
      icon: 'trend-up',
      title: 'Insights mensuales',
      description: 'Visualizá balances y tendencias de gasto mes a mes, sin planillas.'
    },
    {
      icon: 'bank',
      title: 'Múltiples cuentas',
      description: 'Bancos, efectivo, tarjetas: todas tus cuentas en un solo lugar.'
    },
    {
      icon: 'repeat',
      title: 'Servicios recurrentes',
      description: 'Suscripciones y facturas periódicas, con recordatorio de vencimiento.'
    },
    {
      icon: 'document',
      title: 'Exportar a PDF',
      description: 'Sacá tus estadísticas y movimientos en PDF cuando los necesites.'
    }
  ];
}
