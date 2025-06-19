from typing import TextIO, Tuple, Dict, Callable, List
import os
import sys
import functools
from datetime import datetime

help_msg = """
Modulo di utilità pensato per essere eseguito su linea di comando per effettuare operazioni comuni
sui file dataset in formato csv. Comandi disponibili:
"""

TMP_FILENAME = "_datatools_tmp_"

commands: Dict[str, Callable] = {}

now = datetime.now()
datetime_string = now.strftime("%d/%m/%Y %H:%M:%S (h:m:s)")

def command(name: str):
    """Decoratore che trasforma una funzione in un comando eseguibile da terminale
    """
    def decorator(f):

        @functools.wraps(f)
        def wrapper(*args, **kwargs):

            # crea il file temporaneo e logga l'esecuzione di questo comando
            with open(TMP_FILENAME, "w") as f_dst:
                format_args = "{" + ", ".join(args[1:]) + "}"
                subline = f"with args {format_args} " if len(args) > 1 else ""
                f_dst.write(f"# PREPROCESS: Command '{name}' was performed {subline}on {datetime_string}.\n")

            f(*args, **kwargs)

            # elimina il file temporaneo se ancora esiste
            try:
                os.remove(TMP_FILENAME)
            except FileNotFoundError as e:
                pass

        commands[name] = wrapper
        return wrapper

    return decorator

def skip_comments(f: TextIO) -> List[str]:
    line = f.readline()
    heading = [line]
    while line.startswith("#") or line.strip() == "":
        line = f.readline()
        heading.append(line)
    return heading

@command("fixinput")
def anticipa_input(target: str):
    """
    Porta la colonna degli input avanti di un iterazione (questa funzione
    è nata per fixare un bug in cui la colonna di input portava un lag di 1 iterazione)
    """

    with open(target, "r") as f_src:
        headings = skip_comments(f_src) # riga di intestazione

        with open(TMP_FILENAME, "a") as f_dst:
            f_dst.writelines(headings)

            line = f_src.readline()
            line_contents = [st.strip() for st in line.split(",")]
            print(line_contents)
            x = 0
            for line in f_src:
                x+= 1
                input = float(line_contents[1])
                if x == 1: print(input)    
                line_contents = [st.strip() for st in line.split(",")]

                new_line_contents = line_contents.copy()
                new_line_contents[1] = str(input)

                new_line = ", ".join(new_line_contents) + "\n"
                f_dst.write(new_line)

    os.remove(target)
    os.rename(TMP_FILENAME, target)   

@command("retime")
def recenter_time(target: str):
    """
    Riscrive la colonna timestamp di un file in modo tale che il primo frame parta da 0.
    """

    with open(target, "r") as f_src:
        headings = skip_comments(f_src) # tutto ciò che precede i dati
        fist_line_contents = [st.strip() for st in f_src.readline().split(",")]
        time_offset = int(fist_line_contents[0])
        print("time offset: ", time_offset)

        with open(TMP_FILENAME, "a") as f_dst:
            f_dst.writelines(headings)

            fist_line_contents[0] = "0" # il primo timestamp è sempre a zero
            first_line = ", ".join(fist_line_contents) + "\n"
            f_dst.write(first_line) # scrive la prima riga

            for line in f_src:
                #print(line, end="")
                line_contents = [st.strip() for st in line.split(",")]
                new_time = int(line_contents[0]) - time_offset
                new_line_contents = [str(new_time)] + line_contents[1:]
                new_line = ", ".join(new_line_contents) + "\n"
                f_dst.write(new_line)

    os.remove(target)
    os.rename(TMP_FILENAME, target)

@command("constrain")
def constrain_input(target: str, bound_str: str):
    """
    Riscrive la colonna di input restringendo l'ingresso al range indicato
    """

    bound = float(bound_str)

    with open(target, "r") as f_src:
        headings = skip_comments(f_src) # riga di intestazione
        with open(TMP_FILENAME, "a") as f_dst:
            f_dst.writelines(headings)

            for line in f_src:
                #print(line, end="")
                line_contents = [st.strip() for st in line.split(",")]
                input = float(line_contents[1])
                input = max(min(input, bound), -bound)    #constrain input
                line_contents[1] = str(input)
                new_line = ", ".join(line_contents) + "\n"
                f_dst.write(new_line)

    os.remove(target)
    os.rename(TMP_FILENAME, target)

@command("duration")
def get_timespan(target: str):
    """
    Prende un file e legge la durata totale della sessione di acquisizione.
    """

    with open(target, "r") as f:
        skip_comments(f) # intestazione
        line_contents = f.readline().split(",") # prima riga di dati
        start_time = int(line_contents[0])

        print(start_time)

        for line in f:
            line_contents = line.split(",")
            time = int(line_contents[0])
        else:
            time = 0

    secs = (time - start_time) * 0.001
    formatted = f"{int(secs // 60)} minutes and {round(secs % 60, 2)} seconds"
    print(f"Total timespan: {formatted}")

def unwrap(target: str):
    """
    Prende un file contenente i dati senza nessuna newline e li separa in righe.
    """

    with open(target, "r") as f_src:
        heading = f_src.readline() # riga di intestazione
        
        with open(TMP_FILENAME, "w") as f_dst:
            word = ""
            line_contents = []
            while True:
                char = f_src.read(1)
                if not char:
                    print("End")
                    break

                if char == ",":
                    line_contents.append(word.strip())
                    word = ""
                    if len(line_contents) == 6: # una riga intera è stata ritrovata
                        f_dst.write(", ".join(line_contents) + "\n")
                        line_contents.clear()
                    continue
                
                word += char

@command("remdups")
def remove_duplicate_timestamps(target: str):
    """
    Elimina tutte le righe con timestamp duplicato.
    """

    with open(target, "r") as f_src:
        headings = skip_comments(f_src)

        with open(TMP_FILENAME, "a") as f_dst:
            f_dst.writelines(headings)

            current_valid_timestamp = -1

            for line in f_src:
                #print(line, end="")
                line_contents = [st.strip() for st in line.split(",")]
                timestamp = int(line_contents[0])
                # non scrivere la riga nel file se il timestamp è duplicato o è nel passato
                if timestamp <= current_valid_timestamp:
                    continue
                
                current_valid_timestamp = timestamp # altrimenti aggiorna il cvt e scrivi la riga
                new_line_contents = [str(timestamp)] + line_contents[1:]
                new_line = ", ".join(new_line_contents) + "\n"
                f_dst.write(new_line)

    os.remove(target)
    os.rename(TMP_FILENAME, target)

@command("help")
def help():
    """Mostra questo messaggio
    """
    print(help_msg)
    for name, f in commands.items():
        print(name, end="")
        if f.__doc__:
            print("  \t-->\t", f.__doc__.strip())
        else:
            print("  \t-->\t???")

@command("all")
def do_all_processing(path: str):
    """
    Esegue tutti i preprocessamenti usuali per l'impiego di un file per l'analisi
    remdups, retime, duration
    """
    recenter_time(target=path)
    remove_duplicate_timestamps(target=path)
    get_timespan(path)



if __name__ == "__main__":
    if len(sys.argv) > 1:
        commstr = sys.argv[1]

        # ottiene il comando dal dizionario
        func: Callable | None = commands.get(commstr)
        if func:
            # passa tutti i parametri forniti dal terminale direttamente
            func(*sys.argv[2:])
        else:
            print(f"Unknown command: {commstr}")
    else:
        help()
