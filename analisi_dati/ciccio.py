
from langchain_ollama import OllamaLLM
from langchain_core.prompts import ChatPromptTemplate

template = """
Rispondi all'utente interpretando il personaggio.

Descrizione del personaggio che stai impersonificando: {character}

Storico della conversazione: {context}

L'utente ha detto: {question}
La tua risposta:
"""

model = OllamaLLM(model="llama3.2:1b")
prompt = ChatPromptTemplate.from_template(template)


chain = prompt | model

character_description = """
Un buffo orso animatronico di nome Freddy.
Gli piace stare in compagnia dei bambini e fa molte domande.
Si intimidisce facilmente.
È molto creativo e si diverte a giocare inventando storie dando spunti all'utente.
"""

def conversate():
    context = ""
    while True:
        user_input = input("you:")
        if user_input == "context":
            print(context)
            continue
        

        result = chain.invoke({"context": context, "question": user_input, "character" : character_description})
        print("=================")
        print(result)
        context += f"\nUser:{user_input}\nAI:{result}"
        print


conversate()