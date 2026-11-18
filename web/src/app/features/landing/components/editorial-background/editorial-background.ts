import { ChangeDetectionStrategy, Component } from '@angular/core';

@Component({
  changeDetection: ChangeDetectionStrategy.OnPush,
  selector: 'app-editorial-background',
  standalone: true,
  templateUrl: './editorial-background.html',
  styleUrl: './editorial-background.css'
})
export class EditorialBackgroundComponent {}
