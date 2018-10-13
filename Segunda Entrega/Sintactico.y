%{
#include <stdio.h>
#include <stdlib.h>
#include <conio.h>
#include <string.h>
#include "y.tab.h"

FILE *yyin;
char *yytext;
extern int yylineno;

/**** INICIO VARIABLES ****/
char tipoActual[10]={""};
char listaVariables[10][20]={""};
int variableActual=0;
void reinicioVariables();
/**** FIN VARIABLES ****/


/**** INICIO TERCETOS ****/

int IndAsignacion;
int IndExpresion;
int IndTermino;
int IndFactor;
int IndInlist;

struct terceto {
	char *uno;
	char *dos;
	char *tres;
};
struct terceto tercetos[1000];
int terceto_index = 0;

int crearTerceto_ccc(char *uno, char *dos, char *tres);
int crearTerceto_cci(char *uno, char *dos, int tres);
int crearTerceto_cii(char *uno, int dos, int tres);
int crearTerceto_fcc(float uno, char *dos, char *tres);
int crearTerceto_icc(int uno, char *dos, char *tres);
int crearTerceto_cic(char *uno, int dos, char *tres);

void save_tercetos();
/**** FIN TERCETOS ****/

/**** INICIO INLIST ****/
int inlist_indice_id;
int inlist_saltos_a_completar[15];
int inlist_cant_saltos;

/**** FIN INLIST ****/

/**** INICIO IF ****/
char valor_comparacion[3];
int if_salto_a_completar;
int if_indice_primercond;
/**** FIN IF ****/
%}

%union {
int intVal;
double realVal;
char *strVal;
}

%token <strVal>ID <intVal>CTE_INT <strVal>CTE_STRING <realVal>CTE_REAL
%token ASIG OP_SUMA OP_RESTA OP_MULT OP_DIV
%token MENOR MAYOR IGUAL DISTINTO MENOR_IGUAL MAYOR_IGUAL
%token INLIST AVG
%token WHILE ENDWHILE
%token IF ELSE ENDIF
%token P_A P_C C_A C_C
%token COMA PUNTO_COMA DOS_PUNTOS
%token AND OR NOT
%token INT FLOAT STRING 
%token DECVAR ENDDEC
%token READ WRITE

%start start

%%

start: programa { printf("\n\n\tCOMPILACION EXITOSA!!\n\n\n"); }
	 |			{ printf("\n El archivo 'Prueba.Txt' no tiene un programa\n"); }
	 ;

programa: declaracion { printf("Declaracion OK\n"); } bloque
        | bloque
		;
		
declaracion: DECVAR variables ENDDEC
		   | DECVAR ENDDEC
		   ;
		   
variables: variables listavar DOS_PUNTOS tipo { guardarTipos(variableActual, listaVariables, tipoActual); reinicioVariables(); }
	     | listavar DOS_PUNTOS tipo { guardarTipos(variableActual, listaVariables, tipoActual); reinicioVariables(); }   
         ;

listavar: listavar COMA ID { strcpy(listaVariables[variableActual++],$3); insertar_id_en_ts($3); }
	    | ID { strcpy(listaVariables[variableActual++],$1); insertar_id_en_ts($1); } 
        ;
	
tipo: INT    { strcpy(tipoActual,"INT"); }
    | FLOAT  { strcpy(tipoActual,"REAL"); }
	| STRING { strcpy(tipoActual,"STRING"); }
	;
		
bloque: sentencia
	  | bloque sentencia
	  ;
		
sentencia: asignacion { printf("Asignacion OK\n"); }
		 | iteracion  { printf("Iteracion OK\n"); }
		 | decision   { printf("Decision OK\n"); }
		 | entrada    { printf("Entrada OK\n"); }
		 | salida     { printf("Salida OK\n"); }
		 ;
		 
asignacion: ID ASIG expresion { IndAsignacion = crearTerceto_cii("=", crearTerceto_ccc($1, "",""), IndExpresion); }
		  ;

iteracion: WHILE P_A condicion P_C bloque ENDWHILE
		 ;
		
decision: IF P_A condicion P_C { if_salto_a_completar = crearTerceto_ccc(valor_comparacion, "", ""); } 
			 decision_bloque
		;

decision_bloque: 
		  bloque ENDIF { char *salto = (char*) malloc(sizeof(int)); itoa(terceto_index, salto, 10); tercetos[if_salto_a_completar].dos = salto; }
		| bloque { char *salto = (char*) malloc(sizeof(int)); itoa(terceto_index+1, salto, 10); tercetos[if_salto_a_completar].dos = salto; if_salto_a_completar = crearTerceto_ccc("BI", "",""); } ELSE bloque ENDIF { char *salto = (char*) malloc(sizeof(int)); itoa(terceto_index, salto, 10); tercetos[if_salto_a_completar].dos = salto; }
		;

condicion: comparacion
         | comparacion AND comparacion 
		 | comparacion OR comparacion
		 | NOT comparacion
		 | NOT P_A comparacion P_C
		 ;

comparacion: expresion { if_indice_primercond = IndExpresion; } MENOR expresion       { crearTerceto_cii("CMP", if_indice_primercond, IndExpresion); strcpy(valor_comparacion, "BGE"); }
		   | expresion { if_indice_primercond = IndExpresion; } MENOR_IGUAL expresion { crearTerceto_cii("CMP", if_indice_primercond, IndExpresion); strcpy(valor_comparacion, "BGT"); }
		   | expresion { if_indice_primercond = IndExpresion; } MAYOR expresion       { crearTerceto_cii("CMP", if_indice_primercond, IndExpresion); strcpy(valor_comparacion, "BLE"); }
		   | expresion { if_indice_primercond = IndExpresion; } MAYOR_IGUAL expresion { crearTerceto_cii("CMP", if_indice_primercond, IndExpresion); strcpy(valor_comparacion, "BLT"); }
		   | expresion { if_indice_primercond = IndExpresion; } IGUAL expresion       { crearTerceto_cii("CMP", if_indice_primercond, IndExpresion); strcpy(valor_comparacion, "BNE"); }
		   | expresion { if_indice_primercond = IndExpresion; } DISTINTO expresion    { crearTerceto_cii("CMP", if_indice_primercond, IndExpresion); strcpy(valor_comparacion, "BEQ"); }
		   | inlist    { strcpy(valor_comparacion, "BI"); /* si llego hasta acá es que no encontré coincidencia */ }
		   ; 

average: AVG P_A C_A avg_expresiones C_C P_C
		;

avg_expresiones: expresion
			   | expresion COMA avg_expresiones
			   ;

inlist: INLIST P_A ID { existe_en_ts($3); inlist_indice_id = crearTerceto_ccc($3, "", ""); } COMA 
		C_A inlist_expresiones C_C P_C  {   
											// aca completo los saltos por la pos actual de tercetos +1 (por el BI)
											int i;
											for (i=0; i<inlist_cant_saltos; i++) {
												char *salto = (char*) malloc(sizeof(int));
												itoa(terceto_index+1, salto, 10);
												tercetos[inlist_saltos_a_completar[i]].dos = salto;
											}
										}
	  ;

inlist_expresiones: expresion { 
								inlist_cant_saltos = 0;
								IndInlist = crearTerceto_cii("CMP", inlist_indice_id, IndExpresion);
								inlist_saltos_a_completar[inlist_cant_saltos] = crearTerceto_ccc("BEQ", "", "");  
								inlist_cant_saltos++;
								}
		          | inlist_expresiones PUNTO_COMA expresion {
								IndInlist = crearTerceto_cii("CMP", inlist_indice_id, IndExpresion);
								inlist_saltos_a_completar[inlist_cant_saltos] = crearTerceto_ccc("BEQ", "", "");  
								inlist_cant_saltos++;
								}
		          ;
		  
expresion: expresion OP_SUMA termino  { IndExpresion = crearTerceto_cii("+", IndExpresion, IndTermino); }
		 | expresion OP_RESTA termino { IndExpresion = crearTerceto_cii("-", IndExpresion, IndTermino); }
		 | termino  { IndExpresion = IndTermino; }
		 ;
		 
termino: termino OP_MULT factor  { IndTermino = crearTerceto_cii("*", IndTermino, IndFactor); }
	   | termino OP_DIV factor   { IndTermino = crearTerceto_cii("/", IndTermino, IndFactor); }
	   | factor                  { IndTermino = IndFactor; }
	   ;
	   
factor: ID	               { IndFactor = crearTerceto_ccc($1, "", ""); }
	  | constante          
	  | P_A expresion P_C  { IndFactor = IndExpresion; }
	  | average           { printf("AVG OK\n"); }
	  ;
	  
constante: CTE_INT    { IndFactor = crearTerceto_icc($1, "", ""); }
         | CTE_STRING { IndFactor = crearTerceto_ccc($1, "", ""); }
		 | CTE_REAL   { IndFactor = crearTerceto_fcc($1, "", ""); }
		 ;

entrada: READ ID
       ;
	   
salida: WRITE CTE_STRING
      | WRITE ID 			{ existe_en_ts($2); }
	  ;
	  
%%

int main(int argc,char *argv[])
{
  
  if ((yyin = fopen(argv[1], "rt")) == NULL)
  {
	printf("\nNo se puede abrir el archivo: %s\n", argv[1]);
  }
  else
  {
	yyparse();
	//mostrar_ts();
	save_reg_ts();
	save_tercetos();
  }
  fclose(yyin);
  return 0;
}

int yyerror(char *errMessage)
{
   printf("(!) ERROR en la linea %d: %s\n",yylineno,errMessage);
   fprintf(stderr, "Fin de ejecucion.\n");
   system ("Pause");
   exit (1);
}

void reinicioVariables() {
	variableActual=0;
    strcpy(tipoActual,"");
}


/* Tercetos */
int crearTerceto_ccc(char *uno, char *dos, char *tres) {
	struct terceto terc;
	int index = terceto_index;
	terc.uno = uno;
	terc.dos = dos;
	terc.tres = tres;
	tercetos[index] = terc;
	terceto_index++;
	return index; // devuelvo la pos del terceto creado
}

int crearTerceto_cci(char *uno, char *dos, int tres) {
	char *tres_char = (char*) malloc(sizeof(int));
	itoa(tres, tres_char, 10);
	
	return crearTerceto_ccc(uno, dos, tres_char);
}

int crearTerceto_cii(char *uno, int dos, int tres) {
	struct terceto terc;
	int index = terceto_index;

	char *dos_char = (char*) malloc(sizeof(int));
	itoa(dos, dos_char, 10);
	
	return crearTerceto_cci(uno, dos_char, tres);
}

int crearTerceto_fcc(float uno, char *dos, char *tres) {
	char *uno_char = (char*) malloc(sizeof(float));
	snprintf(uno_char, sizeof(float), "%f", uno);
	
	return crearTerceto_ccc(uno_char, dos, tres);
}

int crearTerceto_icc(int uno, char *dos, char *tres) {
	char *uno_char = (char*) malloc(sizeof(int));
	itoa(uno, uno_char, 10);
	
	return crearTerceto_ccc(uno_char, dos, tres);
}

int crearTerceto_cic(char *uno, int dos, char *tres) {
	char *dos_char = (char*) malloc(sizeof(int));
	itoa(dos, dos_char, 10);
	
	return crearTerceto_ccc(uno, dos_char, tres);
}

void save_tercetos() {
	FILE *file = fopen("Intermedia.txt", "a");
	
	if(file == NULL) 
	{
    	printf("(!) ERROR: No se pudo abrir el txt correspondiente a la generacion de codigo intermedio\n");
	}
	else 
	{
		int i = 0;
		for (i;i<terceto_index;i++) {
			printf("%d (%s, %s, %s)\n", i, tercetos[i].uno, tercetos[i].dos, tercetos[i].tres);
			fprintf(file, "%d (%s, %s, %s)\n", i, tercetos[i].uno, tercetos[i].dos, tercetos[i].tres);
		}
		fclose(file);
	}
}