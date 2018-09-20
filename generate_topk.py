import pandas as pd
import numpy as np
import sys
def generate_topk(rank_all,all_attr,topk,name):
	output=list(pd.read_csv(all_attr,sep="\t",header=None)[0])
	ranked=list(pd.read_csv(rank_all).iloc[:,0])
	for row in ranked[1+topk:]:
	    tmp=row.split("\t")
	    if len(tmp)==2:
	        attr=tmp[0]
	        entry=attr+" never"
	        if entry not in output:
	            output.append(entry)
	pd.DataFrame(output).to_csv(name+"_temp.attr",header=None,index=None,sep="/")


if __name__ == '__main__':
	rank_all=sys.argv[1]
	all_attr=sys.argv[2]
	topk=int(sys.argv[3])
        name=sys.argv[4]
	generate_topk(rank_all,all_attr,topk,name)
