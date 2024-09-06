#Quick remember
#Control | Pas Palu | 2
#Case | Palu | 1

# Fonctions préalable à l'interface


## Setting up de la connexion python R
#import os 
#os.environ['R_HOME'] = "C:\Program Files\R\R-4.4.1"

import rpy2.robjects as robjects
r = robjects.r

from rpy2.robjects import pandas2ri
pandas2ri.activate()

r('library')('randomForest') #Nécessaire de charger la library randomForest dans l'environnement R du fait du type de modèle employé




## Fonction d'insertion des données

def inserer (a,b,c,d,e,f,g,h,i,j):
    
    
    #Mise en place de la connexion à la base de donnée   
    from sqlalchemy import URL, create_engine
    connection_string = URL.create('postgresql',username='prototype_owner',password='nT1VQRwHe5IN',host='ep-jolly-dew-a2pnc8th.eu-central-1.aws.neon.tech',database='prototype')
    engine = create_engine(connection_string, connect_args={'sslmode':'require'})
    
    
    #Définition de class Test pour l'insertion des données
    from sqlalchemy.orm import sessionmaker
    from sqlalchemy import Column, String,Table, Column, Integer, Float, MetaData,update
    from sqlalchemy.orm import declarative_base, relationship
    from sqlalchemy.engine import reflection
    Base = declarative_base()
    Session = sessionmaker(bind=engine)
    session = Session()

    class Test(Base):
        __tablename__ = 'test'

        id = Column(Integer, primary_key=True)
        Age = Column(Integer)
        DSC = Column(Integer)
        Hbj1 = Column(Float)
        plaquettes = Column(Float)
        CRP = Column(Float)
        PCT = Column(Float)
        Temp = Column(Float)
        modele = Column(Float)
        test_clinique = Column(Float)
        DateTime = Column(String(60))
        
    # L'objet class Test prêt pour insertion dans la bd
    data= Test(Age=a,DSC=b, Hbj1=c, plaquettes=d, CRP=e,PCT=f,Temp=g, modele=h,test_clinique=i,DateTime=j)
    session.add_all([data])
    session.commit()


## Fonction "formatting" pour convertir la donnée en objet R adéquat
def formatting (dataframe): 
    return(pandas2ri.py2rpy(dataframe))

## Fonction "response" pour récupérer la prédiction
def response(path_model,dataframe) : 
    model = r.readRDS(path_model)
    result = r('predict')(model, dataframe, type="response")
    return float(result[0])

## Fonction "response_prob" pour récupérer la probabilité
def response_prob(path_model,dataframe) : 
    model = r.readRDS(path_model)
    result = r('predict')(model, dataframe, type="prob")
    return float(result[0][0])

## Fonction formatting de la sélection radio
def radio(input): 
    return 1.0 if input==":red[Paludisme] :mosquito:"else 2.0

## Fonction formatting pour l'affichage du résultat du modèle
def affichage(input):
    return "Paludisme" if input==1 else "Pas Paludisme"




# Mise en place de l'interface
import streamlit as st
import pandas as pd
pd.DataFrame.iteritems = pd.DataFrame.items

# Titre de l'application
st.title("📋 Prédiction de Paludisme Pédiatrique")

st.markdown("""
<style>
.big-font {
    font-size:25px !important;
    color: black;
}
.stNumberInput input, .stSelectbox box, .stRadio radio {
    border: none;
    box-shadow: 0 1px 3px rgba(0, 0, 0, 0.1);
    padding: 7px;
    margin-bottom: 2px;
}
.stButton button {
    background-color: #4B9CD3;
    color: white;
}
</style>
""", unsafe_allow_html=True)

st.markdown("""<h2 class="big-font">Veuillez entrer les informations du patient :  </h2>
            """, unsafe_allow_html=True)

# Champs de saisie des caractéristiques cliniques
col1, col2 = st.columns(2)

with col1:
    age = st.number_input("Âge en mois*", min_value=0.0, max_value=120.0, value=2.0, key="age")
    duree = st.number_input("Durée Symptômes - Consultation (en jours)", min_value=0.0, key="duree")
    hbj1 = st.number_input("HbJ1 (g/dl)", min_value=0.0, key="hbj1")
    plaquette = st.number_input("Plaquettes (nb/mm3) *", min_value=0.0, key="plaquette")
    evaluer = st.button("Evaluer") # Bouton pour évaluer la probabilité
    st.write("Puis")
    soumission = st.button("Soumettre") # Bouton pour soumettre les informations
    

with col2:
    crp= st.number_input("CRP (mmg/L)", min_value=0.0, key="crp")
    pct = st.number_input("PCT (μg/L) *", min_value=0.0,value=0.0, key="pct")
    temp= st.number_input("Température (°C)", min_value=0.0, value=36.0, key="temp")
    st.write("")
    st.write("")



if evaluer:   
    
    # Vérification des champs obligatoires
    if plaquette == 0.0 or pct == 0.0 or age== 0 :
        st.error("Veuillez remplir les champs :  Plaquettes (nb/mm3) et PCT (μg/L)")
    else:
    
    # Stockage des données dans un DataFrame
        data = {
            "Age": [age],
            "DSC": [duree],
            "HbJ1": [hbj1],
            "plaquettes": [plaquette],
            "CRP": [crp],
            "PCT": [pct],
            "Temp": [temp],
        }

        df = pd.DataFrame(data)
        path="random_forest.rds"
        st.write("Probabilité de paludisme :", response_prob(path, formatting(df))*100)
        if response_prob(path, formatting(df))>=0.5 : 
            st.write("<span style='color:red'>En faveur d'un accès palustre : Oui</span>", unsafe_allow_html=True)
            if pct>=6.17 : 
                st.write("<span style='color:red'>Risque d'accès grave : Oui</span>", unsafe_allow_html=True)
            else: 
                st.write("<span style='color:red'>Risque d'accès grave : Non</span>", unsafe_allow_html=True)
            
        else:
            st.write("<span style='color:green'>En faveur d'un accès palustre : Non</span>", unsafe_allow_html=True)

    
    
   
if soumission:
    st.session_state.submitted = True  # Stocker l'état du clic

if st.session_state.get('submitted'):
    
    # Vérification des champs obligatoires
    if plaquette == 0.0 or pct == 0.0 or age==0.0:
        st.error("Veuillez remplir les champs :  Plaquettes (nb/mm3) et PCT (μg/L)")
    
    else: 
        st.markdown("""<h2 class="big-font">Quel est le statut du patient ? </h2>
                """, unsafe_allow_html=True)
        resultat_reel = st.radio("", [":red[Accès Palustre]", ":green[Pas d'accès palustre]"])
        
        valider = st.button("Valider") # 
        
        if valider: 
            
            data = {
                "Age": [age],
                "DSC": [duree],
                "HbJ1": [hbj1],
                "plaquettes": [plaquette],
                "CRP": [crp],
                "PCT": [pct],
                "Temp": [temp]
            }

            df = pd.DataFrame(data)
            path="random_forest.rds"
            result=response(path, formatting(df))   
                
            #Préparation de la date et l'heure
            from datetime import datetime
            now = datetime.now()
                
            #insertion dans la base de données
            inserer(age,duree,hbj1,plaquette,crp,pct,temp,result,radio(resultat_reel),now.strftime("%d/%m/%Y %H:%M:%S"))
                
            st.success("Informations enregistrées!", icon="✅")
        




