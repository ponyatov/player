import os,sys,re

cfg={}
idx=[]
cmt=[]

if __name__ == "__main__":
    with open(sys.argv[1]) as src:
        for i in src.readlines():
            if re.match(r'^[A-Z]',i):
                print(i[:-1])
                var,val = i[:-1].split('=')
                if var not in idx: idx.append(var)
                cfg[var]=val
            else:
                cmt.append(i)
    with open(sys.argv[1],'w') as out:
        for j in cmt:
            print(f'{j}',file=out)
        for i in idx:
            print(f'{i}={cfg[i]}',file=out)
