import os
import pandas as pd
from datetime import datetime
import requests
from io import StringIO
from bs4 import BeautifulSoup
from lxml import html
from sqlalchemy import create_engine
from dotenv import load_dotenv

load_dotenv()

BASE_DIR = "C:\\Users\\PC\\Documents\\Matias\\data_projects\\ETL_proyectos_ciencia_tecnologia\\sample_files"
BASE_URL = "https://datos.gob.ar/dataset/mincyt-proyectos-ciencia-tecnologia-e-innovacion"
DB_URL = os.getenv('DB_URL')

files_dir = os.listdir(BASE_DIR)
print(files_dir)

def connect_db(db_uri):
  engine = create_engine(db_uri)
  try:
    with engine.connect():
      print(f"CONNECTED TO {engine.url}")
    return engine
  except:
    print(f"CANNOT CONNECT TO {engine.url}")

def extract_project_links():
  r = requests.get(BASE_URL)
  soup = BeautifulSoup(r.text, "html.parser")
  divs_pkg_container = soup.find_all('div', class_ = 'pkg-container')
  projects = []
  for container in divs_pkg_container:
    h3_name = container.find_all('h3')
    link_a = container.find_all('a')
    name = [h3.text.strip() for h3 in h3_name]
    link = [link['href'] for link in link_a if 'csv' in link.get('href', '')]
    print({'name': name[0], 'link': link[0] if len(link)>0 else None})
    project_dict = {'name': name[0], 'link': link[0] if len(link)>0 else None}
    print("-------------------project_dict------------------------------")
    print(project_dict)
    projects.append(project_dict)
  print(projects)
  return pd.DataFrame(projects)

def transform_data(df, name_):
  print("---------------------DF INPUT----------------")
  print(df)
  projects_by_years = pd.DataFrame()
  proyecto = pd.DataFrame()
  if name_ == 'proyectos_20':
    print("-------------------------------------------------------------------------------------------------------------------------")
    df_link = df[df['name'].str.contains(name_)]
    print(df_link)
    for index, row in df_link.iterrows():
      name = row['name']
      link = row['link']
      if link is not None:
        print("------------------------------------------------------")
        print(f"name: {name}, año: {name.split('_')[1]}, link: {link}")
        try:
          df_ = pd.read_csv(link, sep=';')
        except Exception as e:
          print(f"Error al procesar el archivo {link}: {e}")
          print("Intentando cargar el archivo local...")
          local_file = os.path.join(BASE_DIR, f"{name}.csv")
          if os.path.exists(local_file):
            print(f"Cargando archivo local: {local_file}")
            df_ = pd.read_csv(local_file, sep=';')
          else:
            print(f"No se encontró el archivo local {local_file}. Saltando este archivo.")
            continue
        anio = name.split("_")[1]
        df_['anio'] = anio
        print({'name': name, 'columns_before_transformation': df_.columns})
        for col in df_.columns:
          if 'fecha' in col:
            df_[col] = pd.to_datetime(df_[col], format='%Y/%m/%d %H:%M:%S.%f', errors='coerce')
          if '_id' in col and list(df_.columns).index(col) == 0:
            df_.rename(columns={col: 'id'}, inplace=True)
        print({'name': name, 'columns': df_.columns})
        if not df_.empty:
          projects_by_years = pd.concat([projects_by_years, df_], ignore_index=True)
      else:
        print("Link inválido o faltante.")
    return projects_by_years
  elif name_ is not 'proyectos_20':
    print("-------------------------------------------------------------------------------------------------------------------------")
    df_link = df[(df['name'].str.contains(name_)) & (df['link'] is not None)]
    print(df_link)
    for index, row in df_link.iterrows():
      name = row['name']
      link = row['link']
      if link is not None:
        print("------------------------------------------------------")
        print(f"name: {name}, año: {name.split('_')[1]}, link: {link}")
        try:
          df_ = pd.read_csv(link, sep=';')
        except Exception as e:
          print(f"Error al procesar el archivo {link}: {e}")
          print("Intentando cargar el archivo local...")
          # Si falla, intentar cargar el archivo local
          local_file = os.path.join(BASE_DIR, f"{name}.csv")
          if os.path.exists(local_file):
            print(f"Cargando archivo local: {local_file}")
            df_ = pd.read_csv(local_file, sep=';')
          else:
            print(f"No se encontró el archivo local {local_file}. Saltando este archivo.")
            continue
        print({'name': name, 'columns_before_transformation': df_.columns})
        if name == 'proyecto_participante':
          df_['id'] = range(1, len(df_) + 1)
          df_ = df_[['id', 'proyecto_id', 'persona_id', 'funcion_id', 'fecha_inicio', 'fecha_fin']]
        elif name == 'proyecto_beneficiario':
          df_['id'] = range(1, len(df_) + 1)
          df_ = df_[['id', 'proyecto_id', 'organizacion_id', 'persona_id', 'financiadora', 'ejecutora', 'evaluadora', 'adoptante', 'beneficiaria', 'adquiriente', 'porcentaje_financiamiento']]
        elif name == 'proyecto_disciplina':
          df_['id'] = range(1, len(df_) + 1)
          df_ = df_[['id', 'proyecto_id', 'disciplina_id']]
        elif name == 'disciplina':
          df_ = df_.drop(df_[df_['id']<=0].index)
        for col in df_.columns:
          if 'fecha' in col:
            df_[col] = pd.to_datetime(df_[col], format='%Y/%m/%d %H:%M:%S.%f', errors='coerce')
          elif '_id' in col and list(df_.columns).index(col) == 0 and name not in ('proyecto_disciplina', 'proyecto_beneficiario', 'proyecto_participante'):
            df_.rename(columns={col: 'id'}, inplace=True)
          elif name == 'ref_FUNCION' and '_desc' in  col:
            df_.rename(columns={col: 'descripcion'}, inplace=True)
          elif name == 'ref_MONEDA' and '_desc' in col:
            df_.rename(columns={col: 'moneda'}, inplace=True)
          elif name == 'ref_MONEDA' and '_iso' in col:
            df_.rename(columns={col: 'simbolo'}, inplace=True)
        print({'name': name, 'columns': df_.columns})
        if not df_.empty:
          proyecto = pd.concat([proyecto, df_], ignore_index=True)
        return proyecto
      else:
        print("Link inválido o faltante.")
  
def load_data(df, table):
  try:
    engine = connect_db(DB_URL)
    df.to_sql(table, engine, if_exists='append', schema='proyectos_ciencia_tecnologia', index=False)
  except Exception as e:
    print(f"Error al cargar los datos en la tabla {table}: str({e})")

if __name__ == '__main__':
  print("-----------------------EMPEZO A CORRER----------------------")
  proyectos = extract_project_links()

  projects_by_years = transform_data(proyectos, 'proyectos_20')
  proyecto_participante = transform_data(proyectos, 'proyecto_participante')
  proyecto_disciplina = transform_data(proyectos, 'proyecto_disciplina')
  proyecto_beneficiario = transform_data(proyectos, 'proyecto_beneficiario')
  disciplina = transform_data(proyectos, 'ref_DISCIPLINA')
  ref_MONEDA = transform_data(proyectos, 'ref_MONEDA')
  ref_TIPO_PROYECTO = transform_data(proyectos, 'ref_TIPO_PROYECTO')
  ref_ESTADO_PROYECTO = transform_data(proyectos, 'ref_ESTADO_PROYECTO')
  ref_FUNCION = transform_data(proyectos, 'ref_FUNCION')

  load_data(ref_FUNCION, 'funcion')
  load_data(ref_ESTADO_PROYECTO, 'estado_proyecto')
  load_data(ref_TIPO_PROYECTO, 'tipo_proyecto')
  load_data(ref_MONEDA, 'moneda')
  load_data(disciplina, 'disciplina')
  load_data(proyecto_participante, 'proyecto_participante')
  load_data(proyecto_disciplina, 'proyecto_disciplina')
  load_data(proyecto_beneficiario, 'proyecto_beneficiario')
  load_data(projects_by_years, 'proyectos')