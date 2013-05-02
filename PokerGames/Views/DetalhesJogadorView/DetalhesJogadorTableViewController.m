//
//  RankingCampeonatoTableViewController.m
//  PokerGames
//
//  Created by Fabiano Rosa on 23/04/13.
//  Copyright (c) 2013 Fabiano Rosa. All rights reserved.
//

#import "DetalhesJogadorTableViewController.h"
#import "AppDelegate.h"
#import "Jogador.h"
#import "Liga.h"
#import "Campeonato.h"
#import "AFAppDotNetAPIClient.h"
#import "MBProgressHUD.h"
#import "DetalhesJogadorCell.h"
#import "ADVTheme.h"
#import "ECSlidingViewController.h"
#import "MenuViewController.h"
#import "RankingTorneioTableViewController.h"

@interface DetalhesJogadorTableViewController () {
    NSArray *arResultadosTorneios;
    NSDictionary *dicTorneioSelecionado;
}

@end

@implementation DetalhesJogadorTableViewController

- (id)initWithStyle:(UITableViewStyle)style
{
    self = [super initWithStyle:style];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (AppDelegate *)appDelegate {
    return (AppDelegate *)[[UIApplication sharedApplication] delegate];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    // configura o header
    id <ADVTheme> theme = [ADVThemeManager sharedTheme];
    
    [ADVThemeManager customizeTableView:self.tableView];
    
    [self.viewHeader setBackgroundColor:[UIColor colorWithPatternImage:[theme viewBackground]]];
    self.viewHeader.layer.borderColor = [UIColor grayColor].CGColor;
    self.viewHeader.layer.borderWidth = 0.4f;
    
    // verifica se foi passado o jogador como parametro
    if (!self.jogador) {
        self.jogador = [self appDelegate].jogadorLogin;
        
        // botao de configuracoes
        UIBarButtonItem *btnMenu = [[UIBarButtonItem alloc]
                                    initWithImage:[PokerGamesUtil menuImage]
                                    style:UIBarButtonItemStyleBordered
                                    target:self
                                    action:@selector(configAction)];
        self.navigationItem.leftBarButtonItem = btnMenu;
        
        if (![self.slidingViewController.underLeftViewController isKindOfClass:[MenuViewController class]]) {
            self.slidingViewController.underLeftViewController  = [self.storyboard instantiateViewControllerWithIdentifier:@"Menu"];
        }
        
        [self.navigationController.view addGestureRecognizer:self.slidingViewController.panGesture];
    }
    
    // busca os resultados dos torneios do jogador
    [self buscaResultadosTorneio];
}

-(IBAction)configAction
{
    [self.slidingViewController anchorTopViewTo:ECRight];
}

-(void) viewDidDisappear:(BOOL)animated
{
    [super viewDidDisappear:animated];
    
    self.title = @"Voltar";
}

-(void)viewDidAppear:(BOOL)animated{
    
    [super viewDidAppear:animated];
}

-(void) viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    self.title = self.jogador.apelido;
    self.headerNomeCamp.text = self.jogador.liga.campeonato.apelido;
    
    if (![self.slidingViewController.underLeftViewController isKindOfClass:[MenuViewController class]]) {
        self.slidingViewController.underLeftViewController  = [self.storyboard instantiateViewControllerWithIdentifier:@"Menu"];
    }
    
    [self.navigationController.view addGestureRecognizer:self.slidingViewController.panGesture];
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    // Return the number of sections.
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    // Return the number of rows in the section.
    return arResultadosTorneios.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"CellResultado";
    DetalhesJogadorCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier forIndexPath:indexPath];
    
    // Configure the cell...
    NSDictionary *resultadoTorneioJogador = arResultadosTorneios[indexPath.row];
    cell.dados = resultadoTorneioJogador;
    
    return cell;
}

#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    dicTorneioSelecionado = arResultadosTorneios[indexPath.row];
    [self performSegueWithIdentifier:@"RankingTorneio" sender:self];
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    // Make sure your segue name in storyboard is the same as this line
    if ([[segue identifier] isEqualToString:@"RankingTorneio"])
    {
        // Get reference to the destination view controller
        RankingTorneioTableViewController *vc = [segue destinationViewController];
        
        // parametros
        vc.idTorneio = [dicTorneioSelecionado valueForKey:@"IdTorneio"];
    }
}

- (void)buscaResultadosTorneiosJogadorWithBlock:(NSNumber *)idLiga
                                  idCampeonato:(NSNumber *)idCampeonato
                                      idJogador:(NSNumber *)idJogador
            constructingBodyWithBlock:(void (^)(NSArray *resultados, NSError *error))block
{
    
    NSString *path = [NSString stringWithFormat:@"Jogadores.svc/ResultadosTorneios/%@/%@/%@", idLiga, idCampeonato, idJogador];
    //NSLog(@"Path: %@", path);
    
    [[AFAppDotNetAPIClient sharedClient] getPath:path parameters:nil success:^(AFHTTPRequestOperation *operation, id JSON) {
        NSArray *postsFromResponse = [JSON valueForKeyPath:@"ResultadosTorneiosResult"];
        if (block) {
            block(postsFromResponse, nil);
        }
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        if (block) {
            NSLog(@"Path: %@", path);
            block([NSArray array], error);
        }
    }];
}

- (void)buscaCabecalhoResultadosWithBlock:(NSNumber *)idLiga
                                   idCampeonato:(NSNumber *)idCampeonato
                                      idJogador:(NSNumber *)idJogador
                      constructingBodyWithBlock:(void (^)(NSDictionary *cabecalho, NSError *error))block
{
    
    NSString *path = [NSString stringWithFormat:@"Jogadores.svc/ResumoResultados/%@/%@/%@", idLiga, idCampeonato, idJogador];
    //NSLog(@"Path: %@", path);
    
    [[AFAppDotNetAPIClient sharedClient] getPath:path parameters:nil success:^(AFHTTPRequestOperation *operation, id JSON) {
        NSDictionary *postsFromResponse = [JSON valueForKeyPath:@"ResumoResultadosResult"];
        if (block) {
            block(postsFromResponse, nil);
        }
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        if (block) {
            NSLog(@"Path: %@", path);
            block([NSDictionary dictionary], error);
        }
    }];
}

- (void) buscaResultadosTorneio {
    MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:self.navigationController.view animated:YES];
    hud.labelText = @"Buscando resultados";
    
    // busca cabecalho dos resultados
    [self buscaCabecalhoResultadosWithBlock:self.jogador.idLiga
                                     idCampeonato:self.jogador.liga.idCampeonato
                                        idJogador:self.jogador.idJogador
                        constructingBodyWithBlock:^(NSDictionary *cabecalho, NSError *error) {
                            
        if (error) {
            [hud hide:YES];
            
            [[[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Erro", nil) message:[error localizedDescription] delegate:nil cancelButtonTitle:nil otherButtonTitles:NSLocalizedString(@"OK", nil), nil] show];
        } else {
            // cabecalho do resultados
            //NSLog(@"cabecalho: %@", cabecalho );
            
            self.lblAlgoz.text = [cabecalho valueForKey:@"Algoz"];
            self.lblColocacao.text = [NSString stringWithFormat:@"%@º", [cabecalho valueForKey:@"Colocacao"]];            
            self.lblITM.text = [cabecalho valueForKey:@"ITM"];
            self.lblMedia.text = [cabecalho valueForKey:@"Media"];
            self.lblParticipacoes.text = [cabecalho valueForKey:@"Participacoes"];
            self.lblPontos.text = [cabecalho valueForKey:@"Pontos"];
            self.lblVitima.text = [cabecalho valueForKey:@"Vitima"];
            
            NSNumber *saldoValue = [cabecalho valueForKey:@"Saldo"];
            double saldo = [saldoValue doubleValue];
            
            if (saldo < 0) {
                self.lblSaldo.textColor = [UIColor redColor];
            } else {
                self.lblSaldo.textColor = [UIColor colorWithRed:(46/255.f) green:(139/255.f) blue:(87/255.f) alpha:1.0f];
            }
            self.lblSaldo.text = [[PokerGamesUtil currencyFormatter] stringFromNumber:saldoValue];
        }
        
    }];
    
    // busca resultados dos torneios
    [self buscaResultadosTorneiosJogadorWithBlock:self.jogador.idLiga
                              idCampeonato:self.jogador.liga.idCampeonato
                                idJogador:self.jogador.idJogador
                 constructingBodyWithBlock:^(NSArray *resultados, NSError *error) {
                     
         [hud hide:YES];
         
         if (error) {
             [[[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Erro", nil) message:[error localizedDescription] delegate:nil cancelButtonTitle:nil otherButtonTitles:NSLocalizedString(@"OK", nil), nil] show];
         } else {
             // resultados do torneio
             //NSLog(@"resultados: %@", resultados );
             arResultadosTorneios = resultados;
             
             // atualiza table
             [self.tableView reloadData];
             
             if (resultados.count <= 0) {
                  [[[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Atenção", nil) message:@"Nenhum resultado encontrado!" delegate:nil cancelButtonTitle:nil otherButtonTitles:NSLocalizedString(@"OK", nil), nil] show];
             }
         }
         
     }];
}

@end
