import pandas as pd
import numpy as np
from os import listdir
import sys
def generate_unused(train,test,response_name,folder):
	train=pd.read_csv(train,sep="\t")
	train_names=list(train.columns.values)
	file_names=listdir(folder)
	if "allfeature.txt" in file_names:
		allfeature=set(pd.read_csv(folder+"/allfeature.txt",header=None)[0])
	else:
		allfeature=None
	unused=[]
	for name in train_names:
		if name==response_name:
			continue
		elif allfeature and name not in allfeature:
			unused.append(name)
		else:
			if type(train[name][0])==str:
				unused.append(name)
			else:
				unique=train[name].unique()
				if len(unique)==1:
					unused.append(name)
	txtfile1=folder+"/preprocess_unused.txt"
	txtfile2=folder+"/trueY.txt"
	txtfile3=folder+"/keyword.txt"
	pd.DataFrame(unused).to_csv(txtfile1,header=None,index=None,sep="/")
	test=pd.read_csv(test,sep="\t")
	test[response_name].to_csv(txtfile2, index=False)
	try:
		test["keyword"].to_csv(txtfile3, index=False)
	except:
		print("not query-asin-like dataset,no keywords given")


if __name__ == '__main__':
	train=sys.argv[1]
	test=sys.argv[2]
	response_name=sys.argv[3]
	folder=sys.argv[4]
	generate_unused(train,test,response_name,folder)
