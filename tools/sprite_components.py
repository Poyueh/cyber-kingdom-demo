"""Connected raster spans used by offline sprite-sheet preparation."""
import numpy as np

def components(mask):
 parents=[]; spans=[]; previous=[]
 def root(i):
  while parents[i]!=i:
   parents[i]=parents[parents[i]]; i=parents[i]
  return i
 for y,row in enumerate(mask):
  edges=np.diff(np.pad(row.astype(np.int8),(1,1)))
  starts=np.flatnonzero(edges==1);ends=np.flatnonzero(edges==-1)
  current=[]; k=0
  for left,right in zip(starts,ends):
   i=len(parents); parents.append(i)
   while k<len(previous) and previous[k][1]<left:k+=1
   j=k
   while j<len(previous) and previous[j][0]<=right:
    parents[root(previous[j][2])]=root(i); j+=1
   current.append((int(left),int(right),i)); spans.append((y,int(left),int(right),i))
  previous=current
 groups={}
 for y,l,r,i in spans:groups.setdefault(root(i),[]).append((y,l,r))
 return sorted(groups.values(),key=lambda a:sum(r-l for _,l,r in a),reverse=True)

