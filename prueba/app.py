import time
from rich.console import Console
from rich.table import Table
from rich.panel import Panel
from rich.progress import track
import psutil

console = Console()

def analizar_sistema():
    console.print(Panel.fit("[bold cyan]🐳 MONITOR DE RECURSOS DEL CONTENEDOR[/bold cyan]", border_style="green"))
    
    # Simulación de procesamiento de tareas dentro del contenedor
    console.print("\n[yellow]Escaneando el entorno del contenedor...[/yellow]")
    for _ in track(range(10), description="[bold green]Procesando métricas..."):
        time.sleep(0.1)

    # Captura de datos del sistema usando psutil
    cpu_uso = psutil.cpu_percent(interval=1)
    ram = psutil.virtual_memory()
    disco = psutil.disk_usage('/')

    # Crear una tabla visual elegante con Rich
    tabla = Table(title="Resultados del Análisis", show_header=True, header_style="bold magenta")
    tabla.add_column("Métrica", style="dim", width=20)
    tabla.add_column("Valor", justify="right")
    tabla.add_column("Estado", justify="center")

    # Evaluación de la RAM
    estado_ram = "[green]Óptimo[/green]" if ram.percent < 80 else "[red]Alto[/red]"
    
    tabla.add_row("Uso de CPU", f"{cpu_uso}%", "[green]Normal[/green]")
    tabla.add_row("Memoria RAM Usada", f"{ram.percent}%", estado_ram)
    tabla.add_row("RAM Total", f"{round(ram.total / (1024**3), 2)} GB", "N/A")
    tabla.add_row("Espacio en Disco Usado", f"{disco.percent}%", "[green]OK[/green]")

    console.print("\n", tabla)
    console.print("\n[bold green]✔ ¡Análisis finalizado con éxito dentro del contenedor![/bold green]\n")

if __name__ == "__main__":
    analizar_sistema()
