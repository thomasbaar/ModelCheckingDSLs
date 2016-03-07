//  status: works, takes 0.4 sec
// basically the original solution from Evgeny Bodin with 
// one tiny tweak for pml-editor (removed \ - line ends within #define)

mtype = {Cop, Criminal, Mom, Dad, Girl, Boy, Boat};
 
#define DONE (r[Cop] == 1 && r[Criminal] == 1 &&  r[Mom] == 1 && r[Dad] == 1 &&  r[Girl] == 2 && r[Boy] == 2 && r[Boat] == 1)

#define NotWith(children, with) (r[children] == 2*(1-r[with]))
#define With(children, with)    (r[children] != 2*(1-r[with]))

#define CriminalUnsafe (r[Criminal] != r[Cop] && (r[Criminal] == r[Mom] || r[Criminal] == r[Dad] || With(Boy,Criminal) || With(Girl,Criminal) ))
#define BoysUnsafe ( With(Boy,Mom) && r[Mom]!=r[Dad] )
#define GirlsUnsafe ( With(Girl,Dad) && r[Mom]!=r[Dad] )



mtype prev_dr   = 0;
mtype prev_pass = 0;


inline printMove(driver, passenger, boat)
{
    if
        :: boat == 0 ->
            if
            :: passenger == 0 ->
                printf("%e goes there alone.\n", driver); 
            :: else  ->   
                printf("%e with %e go there.\n", driver, passenger); 
            fi;    
        :: else ->
            if
            :: passenger == 0 ->
                printf("%e goes back alone.\n", driver); 
            :: else  ->   
                printf("%e with %e go back.\n", driver, passenger); 
            fi;    
    fi;    
}

inline update_r()
{
  r[driver] = r[driver] + (1-2*r[Boat]);
  if 
     :: passenger != 0 -> r[passenger] = r[passenger] + (1-2*r[Boat]);
     :: else -> skip;
  fi;
  r[Boat] = 1 - r[Boat];
}

inline move(dr, pass)
{
  printMove(dr, pass, r[Boat]);
  if
    :: dr == prev_dr && pass == prev_pass -> printf("Don't do the same move!\n");
    :: else ->
        update_r(); 
        if          
        :: CriminalUnsafe || BoysUnsafe || GirlsUnsafe ->  
            /* undo move */
            update_r();
         :: else ->          
            prev_dr = dr; prev_pass = pass;
        fi;
  fi;   
}


/* Global array for positions, initially = 0 */
int r[8]; 
/* mtypes are assigned from 1, array are indexed from 0, so the r[0] is not used */

init {
    local mtype driver    = 0; 
    local mtype passenger = 0; 
  
    /* Run */    
    do
      /* move Cop (with anyone or alone) */
      :: r[Cop] == r[Boat] -> driver = Cop;
        /* Choose a 'random' passenger if it is here */
        if
            :: r[Criminal] == r[Boat] -> passenger = Criminal;
            :: r[Mom] == r[Boat] -> passenger = Mom;
            :: r[Dad] == r[Boat] -> passenger = Dad;
            :: With(Boy,Cop) -> passenger = Boy ;
            :: With(Girl,Cop) -> passenger = Girl;
            :: true -> passenger = 0; /* no passenger at all */
        fi;
        move(driver, passenger);

      /* move Dad (with a Boy or with Mom or alone) */
      :: r[Dad] == r[Boat]  -> driver = Dad;
        if
            :: r[Mom] == r[Boat] -> passenger = Mom;
            :: With(Boy,Dad) -> passenger = Boy ;
            :: true -> passenger = 0;  
        fi;
        move(driver, passenger);

      /* move Mom (with a Girl or alone) */
      :: r[Mom] == r[Boat]  -> driver = Mom;
        if
            :: With(Girl,Mom) -> passenger = Girl;  
            :: true -> passenger = 0;  
        fi;
        move(driver, passenger);
  
       :: DONE -> printf("SOLVED\n"); assert(0); break;
       :: else -> printf("WHAT?!\n"); assert(0); break; /* Should never happen! */ 
    od;    
}
