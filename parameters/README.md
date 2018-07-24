not sure how to do settings.  I keep going back to having a group of sets of the following traits:
- matches, defines where the stack applies
  vars, defines the parameters for the stacks or the settings for ssm

We could read all of them in this directory and apply them in incrementing order ( negative and positive)
it's kinda magical glue but it seems simple enough.

Putting it all in SSM seems like it makes sense.  You could run a check to make sure they all exist easier than 
you could cook up your own system, and soon, it will probably support encrypted values.  Until then it's still 
adequate probably, assuming the account has deny-by-default SSM. 

So, then, we're looking for a set of ssm settings.  That automatically, like stacks, is per-region and per-account.  It maybe 
makes sense to start there, either with matches or just with a hardcoded structure for now.  

To be able to dry things out, you could also do includes ... but that starts to sound like a lot of magic.  

I still don't think I've nailed this.  Ansible groups actually do the variable thing nicely and that's what I guess I 
tend to emulate here.


