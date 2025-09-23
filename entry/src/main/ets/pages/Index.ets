import {common} from '@kit.AbilityKit';
//import ViewModel
import TodoListViewModel from '../viewModel/TodoListViewModel'
//import View
import { AllChooseComponent } from '../views/AllChooseComponent';
import { TodoComponent } from '../views/TodoComponent';
import { TodoListComponent } from '../views/TodoListComponent';

@Entry
@Component
struct TodoList {
  @State todoListViewModel: TodoListViewModel = new TodoListViewModel();
  private context = this.getUIContext().getHostContext() as common.UIAbilityContext;

  async aboutToAppear() {
    await this.todoListViewModel.loadTasks(this.context);
  }

  build() {
    Column() {
      Row({ space: 40 }) {
        //全部待办
        TodoComponent()
        //全选
        AllChooseComponent({ todoListViewModel: this.todoListViewModel });
      }
      Column() {
        TodoListComponent({thingViewModelArray: this.todoListViewModel.things})
      }
    }
    .height('100%')
    .width('100%')
    .margin({top: 5, bottom: 5})
    .backgroundColor('#90f1f3f5')
  }
}