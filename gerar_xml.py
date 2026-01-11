import os
import hashlib
import xml.etree.ElementTree as ET
from xml.dom import minidom

def calculate_hash(filepath):
    sha256_hash = hashlib.sha256()
    with open(filepath, "rb") as f:
        for byte_block in iter(lambda: f.read(4096), b""):
            sha256_hash.update(byte_block)
    return sha256_hash.hexdigest()

def generate_xml():
    root = ET.Element("updates")
    # Adicionando as tags que seu Launcher C# espera encontrar
    ET.SubElement(root, "version").text = "1.0.0"
    ET.SubElement(root, "launcher_version").text = "1.0"
    files_node = ET.SubElement(root, "files")

    # '.' indica que o script vai ler tudo na pasta atual
    base_path = '.' 
    
    print(f"Lendo arquivos em: {os.path.abspath(base_path)}...")

    for root_dir, _, files in os.walk(base_path):
        for file in files:
            filepath = os.path.join(root_dir, file)
            
            # Pega o caminho relativo para o XML ficar limpo
            relative_path = os.path.relpath(filepath, base_path).replace("\\", "/")
            
            # Pula arquivos que não devem ir para os jogadores
            if '.git' in filepath or file == 'gerar_xml.py' or file == 'updates.xml' or file.endswith('.pdb'):
                continue
                
            print(f"Processando: {relative_path}")
            f_node = ET.SubElement(files_node, "file")
            f_node.set("name", relative_path)
            f_node.set("hash", calculate_hash(filepath))

    # Salva o XML formatado
    xml_str = minidom.parseString(ET.tostring(root)).toprettyxml(indent="   ")
    with open("updates.xml", "w", encoding="utf-8") as f:
        f.write(xml_str)
    print("\nSUCESSO! O arquivo 'updates.xml' foi gerado corretamente.")

if __name__ == "__main__":
    generate_xml()