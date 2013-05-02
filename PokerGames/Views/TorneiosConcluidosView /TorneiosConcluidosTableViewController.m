//
//  RankingCampeonatoTableViewController.m
//  PokerGames
//
//  Created by Fabiano Rosa on 23/04/13.
//  Copyright (c) 2013 Fabiano Rosa. All rights reserved.
//

#import "TorneiosConcluidosTableViewController.h"
#import "AppDelegate.h"
#import "Jogador.h"
#import "Liga.h"
#import "Campeonato.h"
#import "AFAppDotNetAPIClient.h"
#import "MBProgressHUD.h"
#import "TorneiosConcluidosCell.h"
#import <QuartzCore/QuartzCore.h>
#import "ADVTheme.h"
#import "ECSlidingViewController.h"
#import "MenuViewController.h"
#import "RankingTorneioTableViewController.h"

@interface TorneiosConcluidosTableViewController () {
    NSArray *arTorneios;
    NSDictionary *torneioSelecionado;
}

@end

@implementation TorneiosConcluidosTableViewController

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
    
    // botao de configuracoes
    UIBarButtonItem *btnMenu = [[UIBarButtonItem alloc]
                                   initWithImage:[PokerGamesUtil menuImage]
                                   style:UIBarButtonItemStyleBordered
                                   target:self
                                   action:@selector(configAction)];
    self.navigationItem.leftBarButtonItem = btnMenu;
    
    // busca os torneios concluidos
    [self buscaTorneiosConcluidos];
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
    
    self.title = [self.appDelegate jogadorLogin].liga.campeonato.apelido;
    
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
    return arTorneios.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"CellTorneio";
    TorneiosConcluidosCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier forIndexPath:indexPath];
    
    // Configure the cell...
    NSDictionary *torneio = arTorneios[indexPath.row];
    cell.dados = torneio;
    
    return cell;
}

#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    torneioSelecionado = arTorneios[indexPath.row];
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
        vc.idTorneio = [torneioSelecionado valueForKey:@"IdTorneio"];
    }
}

- (void)buscaTorneiosConcluidosWithBlock:(NSNumber *)idLiga
                                  idCampeonato:(NSNumber *)idCampeonato
            constructingBodyWithBlock:(void (^)(NSArray *torneios, NSError *error))block
{
    
    NSString *path = [NSString stringWithFormat:@"Torneios.svc/Inativos/%@/%@", idLiga, idCampeonato];
    //NSLog(@"Path: %@", path);
    
    [[AFAppDotNetAPIClient sharedClient] getPath:path parameters:nil success:^(AFHTTPRequestOperation *operation, id JSON) {
        NSArray *postsFromResponse = [JSON valueForKeyPath:@"InativosResult"];
        if (block) {
            //NSLog(@"postsFromResponse: %@", postsFromResponse);
            block(postsFromResponse, nil);
        }
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        if (block) {
            NSLog(@"Path: %@", path);
            block([NSArray array], error);
        }
    }];
}

- (void) buscaTorneiosConcluidos {
    MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:self.navigationController.view animated:YES];
    hud.labelText = @"Buscando torneios";
    
    Jogador *jogadorLogin = [self.appDelegate jogadorLogin];
    //NSLog(@"Busca campeonatos da liga %@", jogadorLogin.idJogador);
    
    // busca lista de campeonatos da liga
    [self buscaTorneiosConcluidosWithBlock:jogadorLogin.liga.idLiga
                              idCampeonato:jogadorLogin.liga.campeonato.idCampeonato
                 constructingBodyWithBlock:^(NSArray *torneios, NSError *error) {
                     
         [hud hide:YES];
         
         if (error) {
             [[[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Erro", nil) message:[error localizedDescription] delegate:nil cancelButtonTitle:nil otherButtonTitles:NSLocalizedString(@"OK", nil), nil] show];
         } else {
             // torneios concluidos
             //NSLog(@"torneios: %@", torneios );
             arTorneios = torneios;
             
             // atualiza table
             [self.tableView reloadData];
             
             if (torneios.count <= 0) {
                  [[[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Atenção", nil) message:@"Nenhum torneio encontrado!" delegate:nil cancelButtonTitle:nil otherButtonTitles:NSLocalizedString(@"OK", nil), nil] show];
             }
         }
         
     }];
}

@end
