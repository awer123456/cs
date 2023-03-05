#!/usr/bin/env python
# coding: utf-8

# In[7]:


import pandas as pd
df=pd.read_excel('cs1.xlsx')


# In[8]:


import numpy as np
from sklearn.model_selection import train_test_split
from sklearn.linear_model import LinearRegression 
x=np.array(df['profit']).reshape(-1,1)
y=np.array(df['rate']).reshape(-1,1)
trainx,testx,trainy,testy=train_test_split(x,y,train_size=0.2)
model=LinearRegression().fit(trainx,trainy)
model.score(testx,testy)


# In[9]:


import pickle 
with open("model.pkl","wb")as file: pickle.dump(model,file)


# In[10]:


import pickle
pickle_in= open("model.pkl", "rb") 
model=pickle.load(pickle_in)


# import picklewith open("model.pkl","wb")as file: pickle.dump(model,file)

# In[16]:


import numpy as np
import streamlit as st
model_st=pickle.load(open('model.pkl','rb'))
def pc(模块利润):
    int_f = [float(x)for x in[模块利润]]
    fin_f=[np.array(int_f)]
    prediction=model_st.predict(fin_f)
    prediction=np.round(prediction[0],2)
    return prediction
def main():
    st.title("利润测试工具")
    hteml_temp=''''''
    st.markdown(hteml_temp,unsafe_allow_html=True)
    模块利润=st.text_input("模块利润","Type Here ")
    if st.button("Predict"):
        rt=pc(模块利润)
        st.success('利润占比为{}'.format(rt))
main()


# In[ ]:





# In[ ]:





# In[ ]:





# In[ ]:





# In[ ]:





# In[ ]:





# In[ ]:





# In[ ]:





# In[ ]:




